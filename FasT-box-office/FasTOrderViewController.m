//
//  FasTOrderViewController.m
//  FasT-retail
//
//  Created by Albrecht Oster on 14.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTOrderViewController.h"
#import "FasTOrder.h"
#import "FasTTicketTypesViewController.h"
#import "FasTSeatsViewController.h"
#import "FasTApi.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"
#import "MBProgressHUD.h"

@interface FasTOrderViewController ()

- (void)initSteps;
- (void)pushNextStepController;
- (void)popStepController;
- (void)updateButtons;
- (void)expireOrder;
- (void)showLocalizedAlertWithKey:(NSString *)key;
- (void)toggleBtn:(UIButton *)btn enabled:(BOOL)enabled;
- (void)toggleBtns:(BOOL)toggle;
- (void)disableBtns;
- (void)dismissWithFinished:(BOOL)finished;
- (void)resetOrder;

@end

@implementation FasTOrderViewController

@synthesize order, delegate;

- (id)init
{
    self = [super init];
    if (self) {
        nvc = [[UINavigationController alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expireOrder) name:FasTApiOrderExpiredNotification object:nil];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self resetOrder];
    
    [self addChildViewController:nvc];
	nvc.view.frame = self.view.bounds;
	
	[[self view] addSubview:[nvc view]];
	[[self view] sendSubviewToBack:[nvc view]];
	[nvc didMoveToParentViewController:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[nvc release];
	[nextBtn release];
	[prevBtn release];
	[order release];
    [stepControllers release];
	[super dealloc];
}

- (FasTEvent *)event
{
    return [[FasTApi defaultApi] event];
}

#pragma mark class methods

- (void)initSteps
{
    [order release];
    order = [[FasTOrder alloc] init];
    for (FasTEventDate *date in [[self event] dates]) {
        if ([[date date] isToday]) {
            [order setDate:date];
            break;
        }
    }
    if (![order date]) [order setDate:[[self event] dates][0]];
    
    currentStepIndex = -1;
    
    NSMutableArray *tmpStepControllers = [NSMutableArray array];
    NSArray *stepControllerClasses = @[ [FasTTicketTypesViewController class], [FasTSeatsViewController class] ];
    
    for (Class klass in stepControllerClasses) {
        FasTStepViewController *vc = [[[klass alloc] initWithOrderController:self] autorelease];
        [tmpStepControllers addObject:vc];
    }
    
    [stepControllers release];
    stepControllers = [[NSArray arrayWithArray:tmpStepControllers] retain];
    
    [nvc popToRootViewControllerAnimated:NO];
    [self pushNextStepController];
}

- (void)resetSeating
{
    [[FasTApi defaultApi] resetSeating];
    [[FasTApi defaultApi] unlockSeats];
}

- (void)resetOrder
{
    [self resetSeating];
    [self initSteps];
}

- (void)pushNextStepController
{
    if (++currentStepIndex >= [stepControllers count]) {
        [self dismissWithFinished:YES];
    } else {
        currentStepController = stepControllers[currentStepIndex];
        [self updateButtons];
        [nvc pushViewController:currentStepController animated:YES];
    }
}

- (void)popStepController
{
    if (currentStepIndex <= 0) {
        [self dismissWithFinished:NO];
        
    } else {
        currentStepController = stepControllers[--currentStepIndex];
        
        [self updateButtons];
        [nvc popViewControllerAnimated:YES];
    }
}

- (void)updateButtons
{
    [prevBtn setTitle:NSLocalizedStringByKey((currentStepIndex > 0) ? @"back" : @"cancel") forState:UIControlStateNormal];
}

- (void)updateNextButton
{
    [self toggleBtn:nextBtn enabled:[currentStepController isValid]];
}

- (void)expireOrder
{
    if ([[self presentingViewController] presentedViewController] == self) {
        [self showLocalizedAlertWithKey:@"orderExpiredMessage"];
    } else {
        [delegate orderInViewControllerExpired:self];
    }
}

- (void)showLocalizedAlertWithKey:(NSString *)key
{
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedStringByKey(key) message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];
    [alert show];
}

- (void)toggleWaitingSpinner:(BOOL)toggle
{
    if (toggle) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud setMode:MBProgressHUDModeIndeterminate];
        [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
        [hud setDetailsLabelText:nil];
        [hud show:YES];
    } else {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }
}

- (void)toggleBtn:(UIButton *)btn enabled:(BOOL)enabled
{
    [btn setHidden:!enabled];
}

- (void)toggleBtns:(BOOL)toggle
{
    for (UIButton *btn in @[prevBtn, nextBtn]) {
        [self toggleBtn:btn enabled:toggle];
    }
}

- (void)disableBtns
{
    [self toggleBtns:NO];
}

- (void)dismissWithFinished:(BOOL)finished
{
    [[self delegate] dismissorderViewController:self finished:finished];
    if (!finished) {
        [self resetSeating];
    }
}

#pragma mark actions

- (IBAction)nextTapped:(id)sender {
    if ([currentStepController isValid]) {
        [self pushNextStepController];
    }
}

- (IBAction)prevTapped:(id)sender {
    [self popStepController];
}

#pragma mark ui alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self dismissWithFinished:NO];
}

@end
