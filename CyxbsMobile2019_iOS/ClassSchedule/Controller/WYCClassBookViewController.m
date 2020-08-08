//
//  WYCClassBookViewController.m
//  MoblieCQUPT_iOS
//
//  Created by 王一成 on 2018/9/21.
//  Copyright © 2018年 Orange-W. All rights reserved.
//

#import "WYCClassBookViewController.h"
@interface WYCClassBookViewController ()<UIScrollViewDelegate,WYCClassBookViewDelegate,WYCShowDetailDelegate>
/**课表顶部的小拖拽条*/
@property (nonatomic, weak) UIView *dragHintView;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) UIButton *titleBtn;
@property (nonatomic, assign) BOOL hiddenWeekChooseBar;
@property (nonatomic, strong) NSNumber *nowWeek;
@property (nonatomic, strong) NSMutableArray *titleTextArray;
//@property (nonatomic, strong) IBOutlet UIView *rootView;
@property (nonatomic, strong)  UIScrollView *scrollView;

@property (nonatomic, strong) WMTWeekChooseBar *weekChooseBar;
@property (nonatomic, strong) DateModle *dateModel;


@property (nonatomic, copy) NSString *stuNum;
@property (nonatomic, copy) NSString *idNum;
@property (nonatomic, assign) BOOL isLogin;
@property (nonatomic, assign) BOOL weekChooseBarLock;
//显示（第七周、第六周、本周的）那些条组成的数组
@property (nonatomic, strong)NSMutableArray *currentWeekBars;
//选择去哪一周的一个条
@property (nonatomic, strong)UIView *chooseWeekBar;
//用来储存被分配过空间的weekData结构体，在viewDidDisappear里free分配的空间
@end

@implementation WYCClassBookViewController
- (void)viewDidLoad {
    
    self.navigationController.navigationBar.hidden = YES;
    [super viewDidLoad];
    //self.navigationController.navigationBar.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ModelDataLoadSuccess)
                                                 name:@"ModelDataLoadSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ModelDataLoadFailure)
                                                 name:@"ModelDataLoadFailure" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadView)
                                                 name:@"RemindAddSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadView)
                                                 name:@"RemindEditSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadView)
                                                 name:@"RemindDeleteSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateScrollViewOffSet)
                                                 name:@"ScrollViewBarChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadView)
                                                 name:@"reloadView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginSucceeded)
                                                 name:@"Login_LoginSuceeded" object:nil];
    //默认星期选择条不显示
    self.hiddenWeekChooseBar = YES;
    self.isLogin = NO;
    [self initModel];
    self.index = self.dateModel.nowWeek.integerValue;
}
- (NSString *)stuNum{
    if(_stuNum==nil){
        _stuNum = [UserDefaultTool getStuNum];
    }
    return _stuNum;
}
- (NSString *)idNum{
    if(_idNum==nil){
        _idNum = [UserDefaultTool getIdNum];
    }
    return _idNum;
}
- (DateModle *)dateModel{
    if(_dateModel==nil){
        _dateModel = [DateModle initWithStartDate:DateStart];
    }
    return _dateModel;
}
- (ScheduleType)schedulType{
    //调用一下model的get方法，如果model是空的说明是从storyBoard加载的，所以初始化_schedulType为ScheduleTypePersonal
    
    NSLog(@"%@",self.model);
    
    NSLog(@"------%ld,%ld,%ld,%ld-------",_schedulType,ScheduleTypeWeDate,ScheduleTypePersonal,ScheduleTypeClassmate);
    
    return _schedulType;
}
//如果model是空的，那么说明课表是从storyBoard加载的
- (WYCClassAndRemindDataModel *)model{
    if(_model==nil){
        self.schedulType = ScheduleTypePersonal;
        _model = [[WYCClassAndRemindDataModel alloc] init];
        [_model getClassBookArray:self.stuNum];
        [_model getRemind:self.stuNum idNum:self.idNum];
    }
    return _model;
}
-(void)loginSucceeded{
    [self initModel];
    self.isLogin = YES;
}

-(void)reloadView{
    [self.view removeAllSubviews];
    [self initModel];
    
}


-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    _index = (long)roundf(scrollView.contentOffset.x/_scrollView.frame.size.width);
    [self initTitleLabel];
    [self.weekChooseBar changeIndex:_index];
    
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    NSLog(@"y:%f",self.scrollView.contentOffset.y);
    if (self.scrollView.contentOffset.y <= -100) {
        [self reloadView];
    }
    
}
-(void)updateScrollViewOffSet{
    self.index = self.weekChooseBar.index;
    [UIView animateWithDuration:0.2f animations:^{
        self.scrollView.contentOffset = CGPointMake(self.index*self.scrollView.frame.size.width,0);
    } completion:nil];
    [self initTitleLabel];
    
    
}

- (void)initModel{
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"加载数据中...";
    hud.color = [UIColor colorWithWhite:0.f alpha:0.4f];
    self.weekChooseBarLock = YES;
        [self initWeekChooseBar];
        [self initScrollView];
        [self initTitleLabel];
        [self initNavigationBar];
        [self.model getRemindFromNet:self.stuNum idNum:self.idNum];
}

//WYCClassAndRemindDataModel模型价值数成功后调用
- (void)ModelDataLoadSuccess{
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.weekChooseBarLock = NO;
    @autoreleasepool {
        NSMutableArray *viewArray = [NSMutableArray array];
        self.currentWeekBars = viewArray;
        for (int dateNum = 0; dateNum < self.dateModel.dateArray.count + 1; dateNum++) {
            
            NSMutableArray *day = [[NSMutableArray alloc]initWithCapacity:7];
            
            for (int i = 0; i < 7; i++) {
                
                NSMutableArray *lesson = [[NSMutableArray alloc]initWithCapacity:6];
                
                for (int j = 0; j < 6; j++) {
                    
                    [lesson addObject:[@[] mutableCopy]];
                }
                [day addObject:[lesson mutableCopy]];
            }
            
            NSArray *classBookData = self.model.weekArray[dateNum];
            for (int i = 0; i < classBookData.count; i++) {
                
                NSNumber *hash_day = [classBookData[i] objectForKey:@"hash_day"];
                NSNumber *hash_lesson = [classBookData[i] objectForKey:@"hash_lesson"];
                
                [ day[hash_day.integerValue][hash_lesson.integerValue] addObject: classBookData[i]];
                
            }
            
            
            if (dateNum !=0) {
                NSArray *noteData = self.model.remindArray[dateNum-1];
                
                for (int i = 0; i < noteData.count; i++) {
                    
                    NSNumber *hash_day = [noteData[i] objectForKey:@"hash_day"];
                    NSNumber *hash_lesson = [noteData[i] objectForKey:@"hash_lesson"];
                    
                    [ day[hash_day.integerValue][hash_lesson.integerValue] addObject: noteData[i]];
                }
            }
            
            WYCClassBookView *view = [[WYCClassBookView alloc]initWithFrame:CGRectMake(dateNum*_scrollView.frame.size.width,70, _scrollView.frame.size.width, _scrollView.frame.size.height)];
            view.detailDelegate = self;
    
            
            if (dateNum == 0) {
                [view initView:YES];
                NSArray *dateArray = @[];
                [view addBar:dateArray isFirst:YES];
            }else{
                [view initView:NO];
                [view addBar:self.dateModel.dateArray[dateNum-1] isFirst:NO];
            }
//            UIView *titleView = [[UIView alloc]initWithFrame:CGRectMake(view.frame.size.width/15-10,-20,60,30)];
            UIView *titleView = [[UIView alloc]initWithFrame:CGRectMake(0,-20,MAIN_SCREEN_W,30)];
            
            if (@available(iOS 11.0, *)) {
                titleView.backgroundColor = [UIColor colorNamed:@"ClassScedulelabelColor"];
                       } else {
                            titleView.backgroundColor = [UIColor whiteColor];
                       }
          
//            CGFloat titleLabelWidth = SCREEN_WIDTH * 0.3;
            UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(MAIN_SCREEN_W*0.0427, 0, MAIN_SCREEN_W*0.22, MAIN_SCREEN_H*0.0391)];
            titleLabel.backgroundColor = UIColor.whiteColor;
//            UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.titleView.width - titleLabel)/ 2, 0, titleLabel, titleView.height)];
            NSMutableArray *titleArray = [@[@"整学期",@"第一周",@"第二周",@"第三周",@"第四周",@"第五周",@"第六周",@"第七周",@"第八周",@"第九周",@"第十周",@"第十一周",@"第十二周",@"第十三周",@"第十四周",@"第十五周",@"第十六周",@"第十七周",@"第十八周",@"第十九周",@"第二十周",@"二十一周",@"二十二周",@"二十三周",@"二十四周",@"二十五周"] mutableCopy];
            
            
            
            //_____________________为了添加“回到本周”的按钮而增加的改动_____________________________
//            titleLabel:第x周 titleView：titleLabel的背景条
                
            if(self.dateModel.nowWeek.integerValue==dateNum){
                
                //nowWeekLabel显示“本周”的那个label
                UILabel *nowWeekLabel = [[UILabel alloc] init];
                [titleView addSubview: nowWeekLabel];
                nowWeekLabel.text = @"(本周)";
                nowWeekLabel.font = [UIFont fontWithName:@".PingFang SC" size: 15];
                nowWeekLabel.textColor = [UIColor colorNamed:@"color21_49_91&#F0F0F2"];
                nowWeekLabel.frame = CGRectMake(MAIN_SCREEN_W*0.2627, 0.009*MAIN_SCREEN_H, 0.12*MAIN_SCREEN_W, 0.0259*MAIN_SCREEN_H);
                
                
                //rightArrayBtn是显示右箭头那个按钮
                UIButton *rightArrayBtn = [[UIButton alloc] init];
                [titleView addSubview:rightArrayBtn];
                [rightArrayBtn setTitle:@">" forState:(UIControlStateNormal)];
                rightArrayBtn.titleLabel.font = [UIFont fontWithName:@".PingFang SC" size: 15];
                [rightArrayBtn setTitleColor:[UIColor colorNamed:@"color21_49_91&#F0F0F2"] forState:(UIControlStateNormal)];
                
                [rightArrayBtn setFrame:(CGRectMake(MAIN_SCREEN_W*0.3827, 0, 7, MAIN_SCREEN_H*0.05))];
                
                
                
                [rightArrayBtn addTarget:self action:@selector(rightArrayBtnClicked) forControlEvents:UIControlEventTouchUpInside];
                NSArray *a = @[nowWeekLabel,rightArrayBtn,titleLabel];
                [viewArray addObject:a];
            }else{
                //rightArrayBtn是显示右箭头那个按钮
                UIButton *rightArrayBtn = [[UIButton alloc] init];
                [titleView addSubview:rightArrayBtn];
                [rightArrayBtn setTitle:@">" forState:(UIControlStateNormal)];
                rightArrayBtn.titleLabel.font = [UIFont fontWithName:@".PingFang SC" size: 15];
                [rightArrayBtn setTitleColor:[UIColor colorNamed:@"color21_49_91&#F0F0F2"] forState:(UIControlStateNormal)];
                [rightArrayBtn setFrame:(CGRectMake(MAIN_SCREEN_W*0.2627, 0, 7, MAIN_SCREEN_H*0.05))];
                //0.0391
                [rightArrayBtn addTarget:self action:@selector(rightArrayBtnClicked) forControlEvents:UIControlEventTouchUpInside];
                
                
                //backBtn是“回到本周”的那个按钮
                UIButton *backBtn = [[UIButton alloc] init];
                [titleView addSubview:backBtn];
                [backBtn setTitle:@"回到本周" forState:(UIControlStateNormal)];
                [backBtn setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
                [backBtn setBackgroundColor:[UIColor colorWithRed:41/255.0 green:33/255.0 blue:209/255.0 alpha:1.0]];
                backBtn.titleLabel.font = [UIFont fontWithName:@".PingFang SC" size: 13];
                backBtn.layer.cornerRadius = MAIN_SCREEN_H*0.0197;
                [backBtn setFrame:(CGRectMake(MAIN_SCREEN_W*0.728, 0, 0.2293*MAIN_SCREEN_W, 0.0394*MAIN_SCREEN_H))];

                [backBtn addTarget:self action:@selector(backNowWeekBtnClicked) forControlEvents:UIControlEventTouchUpInside];
                NSArray *a = @[rightArrayBtn,backBtn,titleLabel];
                [viewArray addObject:a];
            }
//_____________________为了添加“回到本周”的按钮而增加的改动_____________________________
            
            
            
            
            _titleText = titleArray[dateNum];
            titleLabel.text = _titleText;
              titleLabel.textAlignment = NSTextAlignmentLeft;
            if (@available(iOS 11.0, *)) {
                titleLabel.textColor = [UIColor colorNamed:@"color21_49_91&#F0F0F2"];
            } else {
                titleLabel.textColor = [UIColor colorWithRed:21/255.0 green:49/255.0 blue:91/255.0 alpha:1.0];
                // Fallback on earlier versions
            }
              titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
//               self.titleLabel.userInteractionEnabled = YES;
            UIView *dragHintView = [[UIView alloc]initWithFrame:CGRectMake(view.frame.size.width/2-13.5,-28,27,5)];
            if (@available(iOS 11.0, *)) {
                dragHintView.backgroundColor = [UIColor colorNamed:@"draghintviewcolor"];
            } else {
                // Fallback on earlier versions
                dragHintView.backgroundColor = [UIColor whiteColor];
            }
            titleLabel.backgroundColor = [UIColor clearColor];
            
            dragHintView.layer.cornerRadius = 2.5;
            [view addSubview:titleView];
            [titleView addSubview:titleLabel];
            [view addSubview:dragHintView];
            
            switch (self.schedulType) {
                //代表是要显示自己的课表
                case ScheduleTypePersonal:
                    
                    //不知道为什么底下有一个白色的条，挡住了一部分课表，不知道要不要改一下滚动范围，这里没改
                    [view addBtn:day];
                    break;
                    
                //代表是要在没课约页面显示课表
                case ScheduleTypeWeDate:
                    [view addBtnForWedate:day];
                    //禁止交互以防止点击按钮后触发显示自己课表页才有的功能
                    for (UIView *sub in view.scrollView.subviews) {
                        sub.userInteractionEnabled = NO;
                    }
                    //不知道为什么底下有一个白色的条，挡住了一部分课表，所以在这里改一下滚动范围
                    view.scrollView.contentSize = CGSizeMake(0, 675);
                    break;
                    
                //代表是要在同学课表页面显示课表
                case ScheduleTypeClassmate:
                    [view addBtn:day];
                    //禁止交互以防止点击按钮后触发显示自己课表页才有的功能
                    for (UIView *sub in view.scrollView.subviews) {
                        sub.userInteractionEnabled = NO;
                    }
                    //不知道为什么底下有一个白色的条，挡住了一部分课表，所以在这里改一下滚动范围
                    view.scrollView.contentSize = CGSizeMake(0, 675);
                    break;
                default:
                    
                    break;
            }
            
            [_scrollView addSubview:view];
        }
    }
    [_scrollView layoutSubviews];
    self.scrollView.contentOffset = CGPointMake(self.index*self.scrollView.frame.size.width,0);

    [self.view layoutSubviews];
    
}
- (void)ModelDataLoadFailure{
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
   
    UIAlertController *controller=[UIAlertController alertControllerWithTitle:@"网络错误" message:@"数据加载失败" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *act1=[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [controller addAction:act1];
    
    [self presentViewController:controller animated:YES completion:^{
        
    }];
    
    self.scrollView.backgroundColor = [UIColor blueColor];
    UIView *view = [[UIView alloc]initWithFrame:self.scrollView.frame];
    view.backgroundColor = [UIColor blackColor];
    [self.scrollView addSubview:view];
    self.scrollView.contentSize = CGSizeMake(0, self.scrollView.height + 100);
}
- (void)initScrollView{
    //[self.rootView layoutIfNeeded];
    self.scrollView = [[UIScrollView alloc]init];
    [self.scrollView setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-HEADERHEIGHT-NVGBARHEIGHT)];
    _scrollView.contentSize = CGSizeMake(self.dateModel.dateArray.count * _scrollView.frame.size.width, 0);
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    
    [_scrollView removeAllSubviews];
    [_scrollView layoutIfNeeded];
    [self.view addSubview:self.scrollView];
}
- (void)initNavigationBar{
    [self initTitleView];
    [self initRightButton];
}
- (void)initTitleView{
    
    //自定义titleView
    self.titleView = [[UIView alloc]init];
    self.titleView = [[UIView alloc]initWithFrame:CGRectMake(_scrollView.frame.size.width/2-13.5, 0, 120, 40)];
    self.titleView.backgroundColor = [UIColor blueColor];
    [self initTitleLabel];
    [self initTitleBtn];
}
- (void)initTitleLabel{
    if (_titleLabel) {
        [_titleLabel removeFromSuperview];
    }
    CGFloat titleLabelWidth = SCREEN_WIDTH * 0.3;
    self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake((_titleView.width - titleLabelWidth)/ 2, 0, titleLabelWidth, _titleView.height)];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    NSMutableArray *titleArray = [@[@"整学期",@"第一周",@"第二周",@"第三周",@"第四周",@"第五周",@"第六周",@"第七周",@"第八周",@"第九周",@"第十周",@"第十一周",@"第十二周",@"第十三周",@"第十四周",@"第十五周",@"第十六周",@"第十七周",@"第十八周",@"第十九周",@"第二十周",@"二十一周",@"二十二周",@"二十三周",@"二十四周",@"二十五周"] mutableCopy];
    if(self.dateModel.nowWeek.integerValue != 0){
        titleArray[self.dateModel.nowWeek.integerValue] = @"本 周";
    }
    
    
    self.titleText = titleArray[_index];
    self.titleLabel.text = self.titleText;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    self.titleLabel.userInteractionEnabled = YES;
    
    //添加点击手势
    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(updateWeekChooseBar)];
    [self.titleLabel addGestureRecognizer:tapGesture];
    [self.titleView addSubview:self.titleLabel];
}
- (void)initTitleBtn{
    //添加箭头按钮
    if (_titleBtn) {
        [_titleBtn removeFromSuperview];
    }
    self.titleBtn = [[UIButton alloc]initWithFrame:CGRectMake(_titleView.width - 15, 0, 9, _titleView.height)];
    //判断箭头方向
    if (_hiddenWeekChooseBar) {
        [self.titleBtn setImage:[UIImage imageNamed:@"downarrow"] forState:UIControlStateNormal];   //初始是下箭头
    }else{
        [self.titleBtn setImage:[UIImage imageNamed:@"uparrow"] forState:UIControlStateNormal];
    }
    
    [self.titleBtn addTarget: self action:@selector(updateWeekChooseBar) forControlEvents:UIControlEventTouchUpInside];
    [self.titleView addSubview: self.titleBtn];
    
    self.navigationItem.titleView = self.titleView;
}
- (void)initRightButton{
    //添加备忘按钮
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"plus"] style:UIBarButtonItemStylePlain target:self action:@selector(addNote)];
    self.navigationItem.rightBarButtonItem = right;
    
}
//添加备忘
- (void)addNote{
    
    DLReminderViewController *vc = [[DLReminderViewController alloc]init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
//初始化星期选择条
- (void)initWeekChooseBar{
    self.weekChooseBar = [[WMTWeekChooseBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 39*autoSizeScaleY) nowWeek:self.dateModel.nowWeek];
    self.weekChooseBar.hidden = self.hiddenWeekChooseBar;
    [self.weekChooseBar changeIndex:self.index];
    [self.view addSubview:self.weekChooseBar];
}
//更新星期选择条状态
- (void)updateWeekChooseBar{
    if (!self.weekChooseBarLock) {
        
        
        if (self.hiddenWeekChooseBar) {
            self.hiddenWeekChooseBar = NO;
            [UIView animateWithDuration:0.1f animations:^{
                self.weekChooseBar.layer.opacity = 1.0f;
            } completion:^(BOOL finished) {
                self.weekChooseBar.hidden = self.hiddenWeekChooseBar;
            }];
            
            [self initTitleBtn];
            [self updateScrollViewFame];
            
        }else{
            self.hiddenWeekChooseBar = YES;
            [UIView animateWithDuration:0.1f animations:^{
                self.weekChooseBar.layer.opacity = 0.0f;
            } completion:^(BOOL finished) {
                self.weekChooseBar.hidden = self.hiddenWeekChooseBar;
            }];
            [self initTitleBtn];
            [self updateScrollViewFame];
        }
    }
}
-(void)updateScrollViewFame{
    //NSLog(@"num:%lu",(unsigned long)_scrollView.subviews.count);
    if (self.hiddenWeekChooseBar) {

        [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.scrollView setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-HEADERHEIGHT-NVGBARHEIGHT)];
        } completion:nil];
        
        for (int i = 0; i < 26; i++) {
            //NSLog(@"num:%d",i);
            WYCClassBookView *view = _scrollView.subviews[i];
            [view changeScrollViewContentSize:CGSizeMake(0, 606*autoSizeScaleY)];
            [view layoutIfNeeded];
            [view layoutSubviews];
        }
    }else{
        [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.scrollView setFrame:CGRectMake(0, self.weekChooseBar.frame.size.height, SCREEN_WIDTH, SCREEN_HEIGHT-HEADERHEIGHT-NVGBARHEIGHT- self.weekChooseBar.frame.size.height)];
        } completion:nil];


        for (int i = 0; i < 26; i++) {
            WYCClassBookView *view = _scrollView.subviews[i];
            [view changeScrollViewContentSize:CGSizeMake(0, 606*autoSizeScaleY + self.weekChooseBar.frame.size.height)];
            [view layoutIfNeeded];
            [view layoutSubviews];

        }
    }
}
- (void)showDetail:(NSArray *)array{
    if ([[UIApplication sharedApplication].keyWindow viewWithTag:999]) {
        [[[UIApplication sharedApplication].keyWindow viewWithTag:999] removeFromSuperview];
    }
    //初始化全屏view
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    //设置view的tag
    view.layer.shadowOffset = CGSizeMake(0,1.5);
    view.layer.shadowRadius = 5;
    view.layer.shadowOpacity = 0.5;
    view.layer.cornerRadius = 8;
    view.tag = 999;
    
    // 汪明天要改的东西
//    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
//    UIVisualEffectView *blurBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
//    blurBackgroundView.frame = view.frame;
//    [view addSubview:blurBackgroundView];
//    
    
    //往全屏view上添加内容
    WYCShowDetailView *detailClassBookView  = [[WYCShowDetailView alloc]initWithFrame:CGRectMake(0, 2 * SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT)];
    detailClassBookView.chooseClassListDelegate = self;
    [detailClassBookView initViewWithArray:array];
    
    
    //添加点击手势
    UIGestureRecognizer *hiddenDetailView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenDetailView)];
    [detailClassBookView addGestureRecognizer:hiddenDetailView];
    
    
    //显示全屏view
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    view.layer.opacity = 0.0f;
    [view addSubview:detailClassBookView];
    [window addSubview:view];
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
        view.layer.opacity = 1.0f;
        detailClassBookView.layer.opacity = 1.0f;
        detailClassBookView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    } completion:nil];
    
}
- (void)hiddenDetailView{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *view = [window viewWithTag:999];
    [UIView animateWithDuration:0.4f animations:^{
//        [view.subviews[1] setFrame: CGRectMake(0, 2 * SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT)];
        view.layer.opacity = 0.0f;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
}
- (void)clickEditNoteBtn:(NSDictionary *)dic{
    [self hiddenDetailView];
    AddRemindViewController *vc = [[AddRemindViewController alloc]initWithRemind:dic];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];

}
- (void)clickDeleteNoteBtn:(NSDictionary *)dic{
    [self hiddenDetailView];
    NSNumber *noteId = [dic objectForKey:@"id"];
    NSString *stuNum = [UserDefaultTool getStuNum];
    NSString *idNum = [UserDefaultTool getIdNum];

    WYCClassAndRemindDataModel *model = [[WYCClassAndRemindDataModel alloc]init];
    [model deleteRemind:stuNum idNum:idNum remindId:noteId];
    [self reloadView];
}

//周选择条的懒加载
- (UIView *)chooseWeekBar{
    //整学期、第一周、十七周等按钮宽高
    float btnW = 0.17*MAIN_SCREEN_W;
    float btnH = MAIN_SCREEN_H*0.0259;
    if(_chooseWeekBar==nil){
        //chooseWeekBar上面有两个控件：scrollView、左箭头按钮
        UIView *chooseWeekBar = [[UIView alloc] initWithFrame:(CGRectMake(0, 50, MAIN_SCREEN_W, 30))];
        [self.view addSubview: chooseWeekBar];
        _chooseWeekBar = chooseWeekBar;
        
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:(CGRectMake(0, 0, MAIN_SCREEN_W-20, 30))];
//        scrollView.backgroundColor = UIColor.whiteColor;
        scrollView.contentSize = CGSizeMake(5*MAIN_SCREEN_W, 30);
        [chooseWeekBar addSubview:scrollView];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        
        NSMutableArray *titleArray = [@[@"整学期",@"第一周",@"第二周",@"第三周",@"第四周",@"第五周",@"第六周",@"第七周",@"第八周",@"第九周",@"第十周",@"十一周",@"十二周",@"十三周",@"十四周",@"十五周",@"十六周",@"十七周",@"十八周",@"十九周",@"二十周",@"二十一周",@"二十二周",@"二十三周",@"二十四周",@"二十五周"] mutableCopy];
        
        for (int i=0; i<26; i++) {
            //btn是整学期、第五周、十八周 按钮
            UIButton *btn = [[UIButton alloc] init];
            [scrollView addSubview:btn];
            [btn setFrame:(CGRectMake(btnW*i+0.0427*MAIN_SCREEN_W,0.0062*MAIN_SCREEN_H,btnW,btnH))];
            
            [btn setTitle:titleArray[i] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont fontWithName:@".PingFang SC" size: 15];
            [btn setTitleColor:[UIColor colorNamed:@"color21_49_91&#F0F0F2"] forState:UIControlStateNormal];
//            btn.backgroundColor = UIColor.whiteColor;
            btn.tag = i;
            //goToAWeek:用tag来知道点击了哪一个按钮
            [btn addTarget:self action:@selector(goToAWeek:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        //添加左箭头按钮
        UIButton *leftArrowBtn = [[UIButton alloc] init];
        [chooseWeekBar addSubview:leftArrowBtn];
        [leftArrowBtn setTitle:@"<" forState:(UIControlStateNormal)];
        leftArrowBtn.titleLabel.font = [UIFont fontWithName:@".PingFang SC" size: 15];
        [leftArrowBtn setTitleColor:[UIColor colorNamed:@"color21_49_91&#F0F0F2"] forState:(UIControlStateNormal)];
        [leftArrowBtn setFrame:(CGRectMake(MAIN_SCREEN_W*0.9387, 0, 20, 30))];
        [leftArrowBtn addTarget:self action:@selector(leftArrowBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chooseWeekBar;
}

//右箭头点击后调用
- (void)rightArrayBtnClicked{
    NSMutableArray *viewArray =  self.currentWeekBars;
    for (NSArray *a in viewArray) {
        for (UIView *v in a) {
            //把currentWeekBars内部存的子控件全部隐形、不可点击
            v.alpha = 0;
            v.userInteractionEnabled = NO;
        }
    }
    //再把周选择条显形、可点击
    self.chooseWeekBar.userInteractionEnabled = YES;
    self.chooseWeekBar.alpha = 1;
}

//左箭头点击后调用
- (void)leftArrowBtnClicked{
    NSMutableArray *viewArray =  self.currentWeekBars;
    for (NSArray *a in viewArray) {
        //把currentWeekBars内部存的子控件全部显形、可点击
        for (UIView *v in a) {
            v.alpha = 1;
            v.userInteractionEnabled = YES;
        }
    }
    //再把周选择条隐形、不可点击
    self.chooseWeekBar.alpha = 0;
    self.chooseWeekBar.userInteractionEnabled = NO;
}
//回到本周按钮点击后调用
- (void)backNowWeekBtnClicked{
    [UIView animateWithDuration:0.5 animations:^{
        self.scrollView.contentOffset = CGPointMake(self.dateModel.nowWeek.intValue*MAIN_SCREEN_W, 0);
    }];
    
}
//点击了周选择条上的某一周后调用，goToAWeek:用tag来知道点击了哪一个按钮
- (void)goToAWeek:(UIButton*)btn{
    [UIView animateWithDuration:0.5 animations:^{
        self.scrollView.contentOffset = CGPointMake(btn.tag*MAIN_SCREEN_W, 0);
    }];
}


@end


