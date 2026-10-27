#import <UIKit/UIKit.h>

@interface ProbeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property (weak, nonatomic) IBOutlet UIButton *runButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

- (IBAction)runProbe:(id)sender;
- (IBAction)clearOutput:(id)sender;

@end