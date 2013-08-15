//
//  FasTSearchViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasTSearchViewController : UIViewController <UITextFieldDelegate>
{
    UITextField *targetTextField;
}

@property (retain, nonatomic) IBOutlet UITextField *orderField;
@property (retain, nonatomic) IBOutlet UITextField *ticketField;

@end
