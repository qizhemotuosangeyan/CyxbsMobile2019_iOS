//
//  FakeTabBarView.m
//  CyxbsMobile2019_iOS
//
//  Created by Stove on 2020/8/25.
//  Copyright © 2020 Redrock. All rights reserved.
//

#import "FakeTabBarView.h"
@interface FakeTabBarView()

@property (nonatomic, weak) UIView *bottomCoverView;
@property (nonatomic, weak) UIView *dragHintView;

@end
@implementation FakeTabBarView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if (@available(iOS 11.0, *)) {
            self.backgroundColor = [UIColor colorNamed:@"peopleListViewBackColor"];
               } else {
                  self.backgroundColor = [UIColor whiteColor];
               }
        
        self.layer.shadowOffset = CGSizeMake(0, -5);
        self.layer.shadowOpacity = 0.1;
        
        // 遮住下面两个圆角
        UIView *bottomCoverView = [[UIView alloc] init];
        bottomCoverView.backgroundColor = self.backgroundColor;
        [self addSubview:bottomCoverView];
        self.bottomCoverView = bottomCoverView;
        
        UIView *dragHintView = [[UIView alloc] init];
        
        if (@available(iOS 11.0, *)) {
            dragHintView.backgroundColor = [UIColor colorNamed:@"draghintviewcolor"];
        } else {
            // Fallback on earlier versions
            dragHintView.backgroundColor = [UIColor whiteColor];
        }
        dragHintView.layer.cornerRadius = 2.5;
        [self addSubview:dragHintView];
        self.dragHintView = dragHintView;
        
        UILabel *classLabel = [[UILabel alloc] init];
        classLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:22];
        [self addSubview:classLabel];
        self.classLabel = classLabel;
        
        UIImageView *clockImageView = [[UIImageView alloc] init];
        [clockImageView setImage:[UIImage imageNamed:@"nowClassTime"]];
        [self addSubview:clockImageView];
        self.clockImageView = clockImageView;
        
        UILabel *classTimeLabel = [[UILabel alloc] init];
        classTimeLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:12];
        [self addSubview:classTimeLabel];
        self.classTimeLabel = classTimeLabel;
        
        UIImageView *locationImageView = [[UIImageView alloc] init];
        [locationImageView setImage:[UIImage imageNamed:@"nowLocation"]];
        [self addSubview:locationImageView];
        self.locationImageView = locationImageView;
        
        UILabel *classroomLabel = [[UILabel alloc] init];
        classroomLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:12];
        [self addSubview:classroomLabel];
        self.classroomLabel = classroomLabel;
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.bottomCoverView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self);
        make.height.equalTo(@16);
    }];
    
    [self.dragHintView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@27);
        make.height.equalTo(@5);
        make.top.equalTo(self).offset(8);
        make.centerX.equalTo(self);
    }];
    
    [self.classLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(23);
        make.centerY.equalTo(self);
    }];
    
    [self.clockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.classLabel.mas_trailing).offset(22);
        make.centerY.equalTo(self.classLabel);
        make.height.width.equalTo(@11);
    }];
    
    [self.classTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.clockImageView.mas_trailing).offset(3);
        make.centerY.equalTo(self.classLabel);
    }];
    
    [self.locationImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.classTimeLabel.mas_trailing).offset(22);
        make.centerY.equalTo(self.classLabel);
        make.height.width.equalTo(@11);
    }];
    
    [self.classroomLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.locationImageView.mas_trailing).offset(3);
        make.centerY.equalTo(self.classLabel);
    }];
}

/// 课表的一个代理方法，用来更新下节课信息
/// @param paramDict 下节课的数据字典
- (void)updateSchedulTabBarViewWithDic:(NSDictionary *)paramDict{
    if( [paramDict[@"is"] intValue]==1){//有下一节课
        self.classroomLabel.text = paramDict[@"classroomLabel"];
        self.classTimeLabel.text = paramDict[@"classTimeLabel"];
        self.classLabel.text = paramDict[@"classLabel"];
    }else{//无下一节课
        self.classroomLabel.text = @"无课了";
        self.classTimeLabel.text = @"无课了";
        self.classLabel.text = @"无课了";
    }
}


@end