//
//  YIMEditerTextView.m
//  yimediter
//
//  Created by ybz on 2017/11/21.
//  Copyright © 2017年 ybz. All rights reserved.
//

#import <Availability.h>
#import <CoreText/CoreText.h>

#import "YIMEditerTextView.h"
#import "YIMEditerInputAccessoryView.h"
#import "YIMEditerSetting.h"
#import "YIMEditerFontView.h"
#import "YIMEditerParagraphView.h"
#import "YIMEditerFontFamilyManager.h"
#import "YIMEditerDrawAttributes.h"



@interface YIMEditerTextView()<YIMEditerInputAccessoryViewDelegate,UITextViewDelegate,YIMEditerStyleChangeDelegate>{
    
}

@property(nonatomic,strong)NSMutableArray<id<YIMEditerStyleChangeObject>> *allObjects;
@property(nonatomic,strong)YIMEditerDrawAttributes *defualtDrawAttributed;

@end

@implementation YIMEditerTextView


#pragma override super
-(instancetype)init{
    return [self initWithFrame:CGRectZero];
}
-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setUp];
    }
    return self;
}
-(void)awakeFromNib{
    [super awakeFromNib];
    [self setUp];
}
-(void)setUp{
    self.delegate = self;
    self.toNewWindowIsBecomeFirstResponder = true;
    self.defualtDrawAttributed = [self createDefualtDrawAttributes];
    self.allObjects = [NSMutableArray array];
    
    YIMEditerInputAccessoryView *accessoryView = [[YIMEditerInputAccessoryView alloc]init];
    accessoryView.delegate = self;
    accessoryView.frame = CGRectMake(0, 0, self.frame.size.width, 38);
    self.inputAccessoryView = accessoryView;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    CGRect rect = self.inputAccessoryView.frame;
    rect.size.width = CGRectGetWidth(self.frame);
    self.inputAccessoryView.frame = rect;
}
-(void)willMoveToWindow:(UIWindow *)newWindow{
    [super willMoveToWindow:newWindow];
    if (newWindow) {
        if(self.toNewWindowIsBecomeFirstResponder)
            [self becomeFirstResponder];
    }
}


#pragma -mark get set
-(void)setMenus:(NSArray<YIMEditerAccessoryMenuItem *> *)menus{
    NSMutableArray* arr = [NSMutableArray array];
    [arr addObject:[[YIMEditerAccessoryMenuItem alloc]initWithImage:[UIImage imageNamed:@"keyboard"]]];
    [arr addObjectsFromArray:menus];
    _menus = arr;
    ((YIMEditerInputAccessoryView*)self.inputAccessoryView).items = arr;
}

#pragma -mark public method
-(void)addStyleChangeObject:(id<YIMEditerStyleChangeObject>)styleChangeObj{
    styleChangeObj.styleDelegate = self;
    [self.defualtDrawAttributed updateAttributed:[styleChangeObj.defualtStyle outPutAttributed]];
    [self.allObjects addObject:styleChangeObj];
}

#pragma -mark private method
/**从选中range中找到选中的段落range*/
-(NSRange)paragraphRangeWithSelectRange:(NSRange)range{
    NSInteger minRangIndex = range.location;
    for (; minRangIndex > 0 && [self.text characterAtIndex:minRangIndex - 1] != '\n'; minRangIndex--)
        ;
    NSInteger maxRangeIndex = range.location + range.length;
    for (; maxRangeIndex < self.text.length && [self.text characterAtIndex:maxRangeIndex - 1] != '\n'; maxRangeIndex++)
        ;
    return NSMakeRange(minRangIndex, maxRangeIndex - minRangIndex);
}
-(void)setTypingWithAttributed:(YIMEditerDrawAttributes*)attr{
    self.typingAttributes = attr.textAttributed;
}
/**设置文字属性到指定区间*/
-(void)setTextWithAttributed:(YIMEditerDrawAttributes *)attr range:(NSRange)range{
    [self.textStorage setAttributes:attr.textAttributed range:range];
    NSRange paragraphRange = [self paragraphRangeWithSelectRange:range];
    [self.textStorage addAttributes:attr.paragraphAttributed  range:paragraphRange];
}
/**从指定样式文字中提取绘制属性*/
-(YIMEditerDrawAttributes*)attributedFromAttributedText:(NSAttributedString*)text{
    NSRange range = {0,0};
    NSDictionary *attribute = [text attributesAtIndex:0 effectiveRange:&range];
    if (NSEqualRanges(NSMakeRange(0, text.string.length), range)) {
        return [[YIMEditerDrawAttributes alloc]initWithAttributeString:attribute];
    }
    return [self createDefualtDrawAttributes];
}
/**从指定区间提取绘制属性*/
-(YIMEditerDrawAttributes*)attributedFromRange:(NSRange)range{
    YIMEditerMutableDrawAttributes *attributes = [[YIMEditerMutableDrawAttributes alloc]init];
    NSDictionary *textAttributed = [self.textStorage attributesAtIndex:range.location longestEffectiveRange:NULL inRange:range];
    attributes.textAttributed = textAttributed;
    
    NSRange paragraphRange = [self paragraphRangeWithSelectRange:range];
    NSDictionary *paragraphAttributed = [self.textStorage attributesAtIndex:paragraphRange.location longestEffectiveRange:NULL inRange:paragraphRange];
    attributes.paragraphAttributed = paragraphAttributed;
    return attributes;
}
-(YIMEditerDrawAttributes*)createDefualtDrawAttributes{
    YIMEditerDrawAttributes *attr = [[YIMEditerDrawAttributes alloc]init];
    for (id<YIMEditerStyleChangeObject> obj in self.allObjects) {
        [attr updateAttributed:[obj.defualtStyle outPutAttributed]];
    }
    return attr;
}
-(YIMEditerDrawAttributes*)currentAttributes{
    YIMEditerDrawAttributes *attr = [[YIMEditerDrawAttributes alloc]init];
    for (id<YIMEditerStyleChangeObject> obj in self.allObjects) {
        [attr updateAttributed:[obj.currentStyle outPutAttributed]];
    }
    return attr;
}

#pragma -mark delegate functions
/**样式切换时*/
-(void)style:(id)sender didChange:(YIMEditerStyle *)newStyle{
    YIMEditerDrawAttributes *currentAttributes = [self currentAttributes];
    [currentAttributes updateAttributed:[newStyle outPutAttributed]];
    [self setTextWithAttributed:currentAttributes range:self.selectedRange];
    self.typingAttributes = currentAttributes.textAttributed;
}
/**AccessoryView选择时*/
-(void)YIMEditerInputAccessoryView:(YIMEditerInputAccessoryView*)accessoryView clickItemAtIndex:(NSInteger)index{
    [self.menus[index] clickAction];
    self.inputView = [self.menus[index] menuItemInputView];
    [self reloadInputViews];
}


#pragma -mark TextView Delegate Functions
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    NSLog(@"ShouldBeginEditing");
    if ([self.userDelegates respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        return [self.userDelegates textViewShouldBeginEditing:textView];
    }
    return true;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView{
    NSLog(@"ShouldEndEditing");
    if ([self.userDelegates respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        return [self.userDelegates textViewShouldEndEditing:textView];
    }
    return true;
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    NSLog(@"DidBeginEditing");
    if ([self.userDelegates respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.userDelegates textViewDidBeginEditing:textView];
    }
}
- (void)textViewDidEndEditing:(UITextView *)textView{
    NSLog(@"DidEndEditing");
    if ([self.userDelegates respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.userDelegates textViewDidEndEditing:textView];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    NSLog(@"shouldChangeTextInRange");
    for (id<YIMEditerStyleChangeObject> obj in self.allObjects) {
        [self.defualtDrawAttributed updateAttributed:[obj.currentStyle outPutAttributed]];
    }
    self.typingAttributes = self.defualtDrawAttributed.textAttributed;
    
    if ([self.userDelegates respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        return [self.userDelegates textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    return true;
}
- (void)textViewDidChange:(UITextView *)textView{
    NSLog(@"DidChange");
    if ([self.userDelegates respondsToSelector:@selector(textViewDidChange:)]) {
        [self.userDelegates textViewDidChange:textView];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView{
    NSLog(@"DidChangeSelection");
    YIMEditerDrawAttributes *attributes = nil;
    //如果有选中文字，修改选中文字的样式
    if (self.selectedRange.length) {
        attributes = [self attributedFromRange:self.selectedRange];
    }else{
        //当前没有文字 使用默认样式
        if(self.text.length == 0){
            attributes = self.defualtDrawAttributed;
        }else if(self.selectedRange.location > 0){
            //通常取光标前一个字符的属性为当前样式
            //但是如果前一个字符是换行符时，需要取换行符后面的字符样式为当前样式。因为换行符的属性属于上一个段落的，而当前光标位置并不希望得到上一个段落的样式
            if ([self.text characterAtIndex:(self.selectedRange.location + self.selectedRange.length - 1)] == '\n') {
                //如果光标后面还有字符
                if (self.text.length > self.selectedRange.location + self.selectedRange.length) {
                    attributes = [self attributedFromRange:NSMakeRange(self.selectedRange.location, 1)];
                }else{
                    attributes = [self defualtDrawAttributed];
                }
            }else{
                attributes = [self attributedFromRange:NSMakeRange(self.selectedRange.location - 1, 1)];
            }
        }else{
            attributes = [[YIMEditerDrawAttributes alloc]init];
        }
    }
    for (id<YIMEditerStyleChangeObject> obj in self.allObjects) {
        [obj updateUIWithTextAttributes:attributes];
    }
    self.defualtDrawAttributed = attributes;
    [self setTypingWithAttributed:attributes];
    if ([self.userDelegates respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.userDelegates textViewDidChangeSelection:textView];
    }
    NSLog(@"%@",self.typingAttributes);
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction NS_AVAILABLE_IOS(10_0){
    NSLog(@"shouldInteractWithURL");
    if([self.userDelegates respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:interaction:)]){
        return [self.userDelegates textView:textView shouldInteractWithURL:URL inRange:characterRange interaction:interaction];
    }
    return true;
}
- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction NS_AVAILABLE_IOS(10_0){\
    NSLog(@"shouldInteractWithTextAttachment");
    if([self.userDelegates respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:interaction:)]){
        [self.userDelegates textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange interaction:interaction];
    }
    return true;
}

#else
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange{
    if([self.userDelegates respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]){
        return [self.userDelegates textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    return true;
}
- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange{
    if([self.userDelegates respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]){
        [self.userDelegates textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }
    return true;
}
#endif
@end
