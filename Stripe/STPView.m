//
//  STPView.m
//
//  Created by Alex MacCaw on 2/14/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "STPView.h"
#import "PKTextField.h" // Oana change

@implementation STPView

@synthesize paymentView, key, pending;

- (void)setupViews;
{
    self.paymentView = [[PKView alloc] initWithFrame:CGRectMake(0, 0, 290, 55)];
    
    // Oana change - remove the textField background imageView
    for (UIView *view in [self.paymentView subviews]) {
        if ([view isKindOfClass:[UIImageView class]] && ![view isEqual:self.paymentView.placeholderView]) {
            [view removeFromSuperview];
        }
    }
    
    self.paymentView.delegate = self;
    [self addSubview:self.paymentView];
}

- (void)awakeFromNib;
{
    [self setupViews];
}

- (id)initWithFrame:(CGRect)frame andKey:(NSString *)stripeKey
{
    self = [self initWithFrame:frame];
    if (self) {
        self.key = stripeKey;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)paymentView:(PKView *)paymentView withCard:(PKCard *)card isValid:(BOOL)valid
{
    if ([self.delegate respondsToSelector:@selector(stripeView:withCard:isValid:)]) {
        [self.delegate stripeView:self withCard:card isValid:valid];
    }
}

- (void)pendingHandler:(BOOL)isPending
{
    pending = isPending;
    self.userInteractionEnabled = !pending;
}

- (void)createToken:(STPTokenBlock)block
{
    if (pending) return;
    
    if (![self.paymentView isValid]) {
        NSError *error = [[NSError alloc] initWithDomain:StripeDomain
                                                    code:STPCardError
                                                userInfo:@{NSLocalizedDescriptionKey : STPCardErrorUserMessage}];
        
        block(nil, error);
        return;
    }
    
    [self endEditing:YES];
    
    PKCard *card = self.paymentView.card;
    STPCard *scard = [[STPCard alloc] init];
    
    scard.number = card.number;
    scard.expMonth = card.expMonth;
    scard.expYear = card.expYear;
    scard.cvc = card.cvc;
    scard.addressZip = card.addressZip; // Oana change
    
    if (card.addressZip.length < 5) {
        scard.addressZip = [self.addressZip string]; // Oana change
    }
    
    [self pendingHandler:YES];
    
    [Stripe createTokenWithCard:scard
                 publishableKey:self.key
                     completion:^(STPToken *token, NSError *error) {
                         [self pendingHandler:NO];
                         block(token, error);
                     }];
}

// Oana change
- (void)fireCardNumberField {
    [self.paymentView.cardNumberField becomeFirstResponder];
}

// Oana change
- (void)showKeyboard {
    [[self.paymentView nextFirstResponder] becomeFirstResponder];
}

@end
