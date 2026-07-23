#import <UIKit/UIKit.h>

static BOOL isClicking = NO;
static NSTimer *clickTimer = nil;
static BOOL alternateToggle = NO;

// Global UI Elements
static UIView *panelView = nil;
static UIView *statusLight = nil; // On/Off status indicator
static UIButton *menuToggleBtn = nil; // Hide/Show layout button
static UITextField *inputA_X = nil;
static UITextField *inputA_Y = nil;
static UITextField *inputB_X = nil;
static UITextField *inputB_Y = nil;
static UIButton *actionBtn = nil;

%hook UIViewController

- (void)viewDidLoad {
    %orig;
    
    if (panelView) return;
    
    // 1. Create a tiny floating button to Hide/Show the main menu
    menuToggleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    menuToggleBtn.frame = CGRectMake(20, 20, 70, 35);
    menuToggleBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.9];
    [menuToggleBtn setTitle:@"Menu" forState:UIControlStateNormal];
    menuToggleBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    menuToggleBtn.layer.cornerRadius = 8;
    [menuToggleBtn addTarget:self action:@selector(toggleMenuVisibility) forControlEvents:UIControlEventTouchUpInside];
    [[UIApplication sharedApplication].keyWindow addSubview:menuToggleBtn];
    
    // 2. Create the Main Floating Control Panel Container
    panelView = [[UIView alloc] initWithFrame:CGRectMake(40, 65, 220, 200)];
    panelView.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95]; 
    panelView.layer.cornerRadius = 14;
    panelView.layer.borderWidth = 1.0;
    panelView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
    
    panelView.layer.shadowColor = [UIColor blackColor].CGColor;
    panelView.layer.shadowOffset = CGSizeMake(0, 4);
    panelView.layer.shadowOpacity = 0.5;
    panelView.layer.shadowRadius = 5.0;
    
    // 3. Title Label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 10, 150, 20)];
    titleLabel.text = @"Macro Control Panel";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [panelView addSubview:titleLabel];
    
    // 4. ON / OFF Status Light Indicator
    statusLight = [[UIView alloc] initWithFrame:CGRectMake(15, 14, 12, 12)];
    statusLight.backgroundColor = [UIColor colorWithRed:0.92 green:0.26 blue:0.26 alpha:1.0]; // Starts Red (OFF)
    statusLight.layer.cornerRadius = 6;
    [panelView addSubview:statusLight];
    
    // Textbox layout helper
    id (^createTextField)(CGRect, NSString *) = ^id(CGRect frame, NSString *placeholder) {
        UITextField *tf = [[UITextField alloc] initWithFrame:frame];
        tf.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1.0];
        tf.textColor = [UIColor greenColor];
        tf.font = [UIFont fontWithName:@"Courier-Bold" size:13];
        tf.textAlignment = NSTextAlignmentCenter;
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.layer.cornerRadius = 6;
        tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder 
            attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
        return tf;
    };
    
    // 5. Position 1 Text Inputs
    UILabel *lblA = [[UILabel alloc] initWithFrame:CGRectMake(15, 45, 190, 15)];
    lblA.text = @"Position 1 (X , Y):";
    lblA.textColor = [UIColor lightGrayColor];
    lblA.font = [UIFont systemFontOfSize:11];
    [panelView addSubview:lblA];
    
    inputA_X = createTextField(CGRectMake(15, 65, 90, 30), @"X");
    inputA_X.text = @"2072";
    [panelView addSubview:inputA_X];
    
    inputA_Y = createTextField(CGRectMake(115, 65, 90, 30), @"Y");
    inputA_Y.text = @"671";
    [panelView addSubview:inputA_Y];
    
    // 6. Position 2 Text Inputs
    UILabel *lblB = [[UILabel alloc] initWithFrame:CGRectMake(15, 100, 190, 15)];
    lblB.text = @"Position 2 (X , Y):";
    lblB.textColor = [UIColor lightGrayColor];
    lblB.font = [UIFont systemFontOfSize:11];
    [panelView addSubview:lblB];
    
    inputB_X = createTextField(CGRectMake(15, 120, 90, 30), @"X");
    inputB_X.text = @"1078";
    [panelView addSubview:inputB_X];
    
    inputB_Y = createTextField(CGRectMake(115, 120, 90, 30), @"Y");
    inputB_Y.text = @"763";
    [panelView addSubview:inputB_Y];
    
    // 7. Start / Stop Action Button
    actionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    actionBtn.frame = CGRectMake(15, 160, 190, 32);
    actionBtn.backgroundColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    [actionBtn setTitle:@"START ENGINE" forState:UIControlStateNormal];
    actionBtn.layer.cornerRadius = 8;
    actionBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    [actionBtn addTarget:self action:@selector(toggleMacroEngine:) forControlEvents:UIControlEventTouchUpInside];
    [panelView addSubview:actionBtn];
    
    // Draggable layout gestures
    UIPanGestureRecognizer *panPanel = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleUIDrag:)];
    [panelView addGestureRecognizer:panPanel];
    
    UIPanGestureRecognizer *panToggle = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleUIDrag:)];
    [menuToggleBtn addGestureRecognizer:panToggle];
    
    [[UIApplication sharedApplication].keyWindow addSubview:panelView];
}

%new
- (void)toggleMenuVisibility {
    // Collapses or opens the window frame smoothly
    [UIView animateWithDuration:0.2 animations:^{
        panelView.alpha = (panelView.alpha == 0.0) ? 1.0 : 0.0;
    }];
}

%new
- (void)handleUIDrag:(UIPanGestureRecognizer *)gesture {
    UIView *piece = gesture.view;
    CGPoint translation = [gesture translationInView:piece.superview];
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        piece.center = CGPointMake(piece.center.x + translation.x, piece.center.y + translation.y);
        [gesture setTranslation:CGPointZero inView:piece.superview];
    }
}

%new
- (void)toggleMacroEngine:(UIButton *)sender {
    isClicking = !isClicking;
    
    if (isClicking) {
        [panelView endEditing:YES]; // Closes active text keyboard
        
        [sender setTitle:@"STOP ENGINE" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor colorWithRed:0.92 green:0.26 blue:0.26 alpha:1.0]; // Action button goes Red to mean "Stop"
        statusLight.backgroundColor = [UIColor colorWithRed:0.18 green:0.80 blue:0.44 alpha:1.0]; // Status light turns Green (ON)
        
        clickTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 
                                                      target:self 
                                                    selector:@selector(executeMacroLoopSteps) 
                                                    userInfo:nil 
                                                     repeats:YES];
    } else {
        [sender setTitle:@"START ENGINE" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]; // Back to neutral dark
        statusLight.backgroundColor = [UIColor colorWithRed:0.92 green:0.26 blue:0.26 alpha:1.0]; // Status light turns Red (OFF)
        
        [clickTimer invalidate];
        clickTimer = nil;
    }
}

%new
- (void)executeMacroLoopSteps {
    CGFloat xA = [inputA_X.text floatValue];
    CGFloat yA = [inputA_Y.text floatValue];
    CGFloat xB = [inputB_X.text floatValue];
    CGFloat yB = [inputB_Y.text floatValue];
    
    CGPoint targetPoint = alternateToggle ? CGPointMake(xA, yA) : CGPointMake(xB, yB);
    alternateToggle = !alternateToggle;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *targetView = [window hitTest:targetPoint withEvent:nil];
    
    if (targetView && [targetView respondsToSelector:@selector(sendActionsForControlEvents:)]) {
        [(UIControl *)targetView sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

%end
