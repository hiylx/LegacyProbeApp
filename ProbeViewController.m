#import "ProbeViewController.h"
#import <IOKit/IOKitLib.h>
#import <CoreFoundation/CoreFoundation.h>
#import <mach/mach.h>

@interface ProbeViewController ()

@property (nonatomic, strong) dispatch_queue_t probeQueue;

@end

@implementation ProbeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.probeQueue = dispatch_queue_create("com.axiom.legacyprobe", DISPATCH_QUEUE_SERIAL);
    [self appendOutput:@"Legacy IOKit Probe — iOS 27.0.1\nTarget: iPhone 15 Pro (T8130/A17 Pro)\n\nTesting Entry #10 classes:\n  • IOMachPort\n  • IOUserNotification\n  • IOUserIterator\n  • IOUserClient2022\n\nTap 'Run Probe' to test all selectors.\nResults appear here.\n\nKERN_NO_ACCESS / KERN_NOT_SUPPORTED = gate holds\nAny other result = UAF PATH REACHABLE\n"];
}

- (void)appendOutput:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.outputTextView.text = [self.outputTextView.text stringByAppendingString:text];
        // Auto-scroll to bottom
        NSRange bottom = NSMakeRange(self.outputTextView.text.length - 1, 1);
        [self.outputTextView scrollRangeToVisible:bottom];
    });
}

- (IBAction)clearOutput:(id)sender {
    self.outputTextView.text = @"";
}

- (IBAction)runProbe:(id)sender {
    self.runButton.enabled = NO;
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    [self appendOutput:@"\n=== PROBE STARTED ===\n\n"];

    dispatch_async(self.probeQueue, ^{
        [self runLegacyProbe];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.runButton.enabled = YES;
            self.spinner.hidden = YES;
            [self.spinner stopAnimating];
            [self appendOutput:@"\n=== PROBE COMPLETE ===\n"];
        });
    });
}

- (void)runLegacyProbe {
    struct Target {
        const char *displayName;
        const char *className;
        int maxSelector;
    };

    struct Target targets[] = {
        {"IOMachPort", "IOMachPort", 19},
        {"IOUserNotification", "IOUserNotification", 19},
        {"IOUserIterator", "IOUserIterator", 19},
        {"IOUserClient2022", "IOUserClient2022", 19},
        {NULL, NULL, 0}
    };

    int anyReachable = 0;

    for (int i = 0; targets[i].displayName; i++) {
        NSString *name = [NSString stringWithUTF8String:targets[i].displayName];
        NSString *className = [NSString stringWithUTF8String:targets[i].className];

        [self appendOutput:[NSString stringWithFormat:@"\n--- Testing %@ (%@) ---\n", name, className]];

        io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(targets[i].className));
        if (!service) {
            [self appendOutput:[NSString stringWithFormat:@"  [-] IOServiceGetMatchingService failed for %@\n", className]];
            continue;
        }

        [self appendOutput:[NSString stringWithFormat:@"  [+] Found service: 0x%x\n", (unsigned int)service]];

        io_connect_t connect = MACH_PORT_NULL;
        kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
        IOObjectRelease(service);

        if (kr != KERN_SUCCESS) {
            [self appendOutput:[NSString stringWithFormat:@"  [-] IOServiceOpen: 0x%x (%s)\n", kr, [self kernReturnString:kr]]];
            continue;
        }

        [self appendOutput:[NSString stringWithFormat:@"  [+] IOServiceOpen succeeded: connect=0x%x\n", (unsigned int)connect]];

        // Test scalar/scalar externalMethod selectors 0-19
        uint64_t input[2] = {0, 0};
        uint64_t output[2] = {0, 0};
        uint32_t outputCnt = 2;

        int classReachable = 0;
        for (uint32_t selector = 0; selector <= (uint32_t)targets[i].maxSelector; selector++) {
            kr = IOConnectCallScalarMethod(connect, selector, input, 2, output, &outputCnt);
            const char *krStr = [self kernReturnString:kr];

            if (kr != KERN_NOT_SUPPORTED && kr != KERN_NO_ACCESS) {
                [self appendOutput:[NSString stringWithFormat:@"  [!!!] Selector %u: %s (0x%x) <- REACHABLE!\n", selector, krStr, kr]];
                classReachable = 1;
                anyReachable = 1;
            } else if (kr == KERN_INVALID_ARGUMENT) {
                [self appendOutput:[NSString stringWithFormat:@"  [+] Selector %u: KERN_INVALID_ARGUMENT (method exists, bad args)\n", selector]];
                classReachable = 1;
                anyReachable = 1;
            }
        }

        IOServiceClose(connect);

        if (classReachable) {
            [self appendOutput:[NSString stringWithFormat:@"  [***] %@: AT LEAST ONE SELECTOR REACHABLE ***\n", name]];
        } else {
            [self appendOutput:[NSString stringWithFormat:@"  [*] %@: All selectors blocked/not supported\n", name]];
        }
    }

    if (anyReachable) {
        [self appendOutput:@"\n[!!!] RESULT: AT LEAST ONE LEGACY CLASS REACHABLE\n"];
        [self appendOutput:@"[!!!] This provides a userland vector to the UAF without GPU process!\n"];
    } else {
        [self appendOutput:@"\n[xxx] RESULT: ALL LEGACY CLASSES BLOCKED\n"];
        [self appendOutput:@"[xxx] Normal app cannot reach UAF. GPU process context required.\n"];
    }
}

- (const char *)kernReturnString:(kern_return_t)kr {
    switch (kr) {
        case KERN_SUCCESS: return "KERN_SUCCESS";
        case KERN_NO_ACCESS: return "KERN_NO_ACCESS (sandbox/entitlement)";
        case KERN_NOT_SUPPORTED: return "KERN_NOT_SUPPORTED";
        case KERN_INVALID_ARGUMENT: return "KERN_INVALID_ARGUMENT";
        case KERN_FAILURE: return "KERN_FAILURE";
        default: return "UNKNOWN";
    }
}

@end
