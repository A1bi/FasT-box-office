//
//  FasTSearchViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTSearchViewController.h"
#import "FasTOrderDetailsViewController.h"

@interface FasTSearchViewController ()

- (void)moveFieldsUp:(BOOL)up;

@end

@implementation FasTSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setTitle:NSLocalizedStringByKey(@"searchControllerTabTitle")];
        [[self navigationItem] setTitle:NSLocalizedStringByKey(@"searchControllerNavigationTitle")];
    }
    return self;
}

- (void)viewDidLoad
{
    UIView *numberPad = [[[NSBundle mainBundle] loadNibNamed:@"FasTNumberpad" owner:self options:nil] objectAtIndex:0];
    for (UITextField *field in @[[self orderField], [self ticketField]]) {
        [field setText:@""];
        [field setInputView:numberPad];
        [field setDelegate:self];
    }
}

- (void)dealloc {
    [_orderField release];
    [_ticketField release];
    [super dealloc];
}

- (void)moveFieldsUp:(BOOL)up
{
    NSInteger distance = 80 * (up ? -1 : 1);
    [UIView beginAnimations:@"moveUpDown" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration:.3f];
    self.view.frame = CGRectOffset(self.view.frame, 0, distance);
    [UIView commitAnimations];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (targetTextField) {
        UITextField *textField = targetTextField;
        targetTextField = nil;
        [textField resignFirstResponder];
    }
}

#pragma mark text field delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    targetTextField = textField;
    if (textField == _ticketField) {
        [self moveFieldsUp:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UIViewController *vc = nil;
    if (textField == _ticketField) {
        [self moveFieldsUp:NO];
    } else if (targetTextField) {
        vc = [[[FasTOrderDetailsViewController alloc] initWithOrderNumber:[textField text]] autorelease];
    }
    if (vc) [[self navigationController] pushViewController:vc animated:YES];
    [textField setText:@""];
    targetTextField = nil;
}

@end
