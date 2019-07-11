//
//  ViewController.m
//  DCShanreTest
//
//  Created by 单车 on 2019/7/9.
//  Copyright © 2019 单车. All rights reserved.
//

#import "ViewController.h"
#import "WXAuth.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
//- (IBAction)shareMessageToChat:(id)sender {
//    [WXAUTH sendWXMessageAuthReq];
//}
//- (IBAction)shareMessageToFriendsCircle:(id)sender {
//    
//}

- (IBAction)textShare:(id)sender {
    [WXAUTH shareToWechatWithText:@"测试分享" type:1];
}
- (IBAction)imageShare:(id)sender {
    [WXAUTH shareToWechatWithImage:[UIImage imageNamed:@"appicon-60pt"] thumbImage:[UIImage imageNamed:@"appicon-60pt"] type:1];
}
- (IBAction)musicShare:(id)sender {
    [WXAUTH shareToWechatWithMusicTitle:@"这是一个音乐" description:@"这就是一个音乐" thumbImage:[UIImage imageNamed:@"appicon-60pt"] musicUrl:@"https://music.163.com/song?id=480787470&userid=109123181" musicDataUrl:@"http://192.168.2.78:8081/abc.mp3" type:1];
}
- (IBAction)videoShare:(id)sender {
    [WXAUTH shareToWechatWithVideoTitle:@"这是一个视频" description:@"这就是一个视频" thumbImage:[UIImage imageNamed:@"appicon-60pt"] videoUrl:@"https://vd2.bdstatic.com/mda-jdfngevj564bnk2e/sc/mda-jdfngevj564bnk2e.mp4?auth_key=1562750869-0-0-be25aae82f5896a690d240560875a405&amp;bcevod_channel=searchbox_feed&amp;pd=bjh&amp;abtest=all" type:1];
}
- (IBAction)webShare:(id)sender {
    [WXAUTH shareToWechatWithWebTitle:@"这是一个网页" description:@"这就是一个网页" thumbImage:[UIImage imageNamed:@"appicon-60pt"] webpageUrl:@"https://baidu.com" type:1];
}

@end
