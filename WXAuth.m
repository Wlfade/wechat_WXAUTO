//
//  WXAuth.m
//  hongyantub2b
//
//  Created by Apple on 2018/8/23.
//  Copyright © 2018年 Apple. All rights reserved.
//

#import "WXAuth.h"
#import "WXApi.h"

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \

@interface WXAuth ()<WXApiDelegate>

@end

@implementation WXAuth

+ (WXAuth *)sharedInstance{
    
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        
        return [[self alloc] init];
    });
}

- (id)init{
    
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (void)sendWXAuthReq{
    
    if([WXApi isWXAppInstalled]){//判断用户是否已安装微信App
        
        SendAuthReq *req = [[SendAuthReq alloc] init];
        req.state = @"wx_oauth_authorization_state";//用于保持请求和回调的状态，授权请求或原样带回
        req.scope = @"snsapi_userinfo";//授权作用域：获取用户个人信息
        
        [WXApi sendReq:req];
    }else{
        
        NSLog(@"未安装微信应用或版本过低");
    }
}
- (BOOL)handleOpenURL:(NSURL *)url{
    
    //处理回调（从微信返回原来的APP时候使用）
    if([url.host isEqualToString:@"platformId=wechat"] || [url.host isEqualToString:@"oauth"]){//微信WeChat分享回调
        
        return [WXApi handleOpenURL:url delegate:self];
    }else{
        
        return NO;
    }
}

/**
 Delegate回调方法
 */
- (void)onResp:(id)resp{
    if([resp isKindOfClass:[SendAuthResp class]]){//判断是否为授权登录类
        
        SendAuthResp *req = (SendAuthResp *)resp;
        if([req.state isEqualToString:@"wx_oauth_authorization_state"]){//微信授权成功
            
            if(req.errCode == 0){
                
                NSLog(@"获取code：%@", req.code);
                
//                req.code;
            }
        }
    }
    if([resp isKindOfClass:[SendMessageToWXResp class]]){
        
        SendMessageToWXResp *req = (SendMessageToWXResp *)resp;
        //这里不再返回用户是否分享完成事件，即原先的cancel事件和success事件将统一为success事件
        //        if(req.errCode == 0){
        //            //分享成功
        //        }
    }
}
//- (void)sendWXMessageAuthReq{
//    if([WXApi isWXAppInstalled]){//判断当前设备是否安装微信客户端
//        
//        //创建多媒体消息结构体
//        WXMediaMessage *message = [WXMediaMessage message];
//        message.title = @"【爆款直降 盛夏特惠】【29.9免邮 限量买3免1】清新持久自然GUCCMI香水";//标题
//        message.description = @"我在京东发现了一个不错的商品，赶快来看看吧。";//描述
//        [message setThumbImage:[UIImage imageNamed:@"appicon-60pt"]];//设置预览图
//        
//        //创建网页数据对象
//        WXWebpageObject *webObj = [WXWebpageObject object];
//        //        webObj.webpageUrl = @"[https://open.weixin.qq.com](https://open.weixin.qq.com)";//链接
//        webObj.webpageUrl = @"https://baidu.com";//链接
//        
//        message.mediaObject = webObj;
//        
//        SendMessageToWXReq *sendReq = [[SendMessageToWXReq alloc] init];
//        sendReq.bText = NO;//不使用文本信息
//        sendReq.message = message;
//        //        sendReq.scene = WXSceneSession;//分享到好友会话
//        sendReq.scene = WXSceneTimeline;//分享到好友会话
//        
//        
//        [WXApi sendReq:sendReq];//发送对象实例
//    }else{
//        
//        //未安装微信应用或版本过低
//        NSLog(@"未安装微信应用或版本过低");
//    }
//}

- (void)shareToWechatWithText:(NSString *)content type:(NSUInteger)type {
    if([WXApi isWXAppInstalled]){//判断当前设备是否安装微信客户端
        SendMessageToWXReq *req = [[SendMessageToWXReq alloc]init];
        req.text = content;
        req.bText = YES;
        req.scene = (int)type;
        [WXApi sendReq:req];}
    else{
        //未安装微信应用或版本过低
        NSLog(@"未安装微信应用或版本过低");
    }
}

- (void)shareToWechatWithImage:(UIImage *)image thumbImage:(UIImage *)thumbImage type:(NSUInteger)type {
    WXMediaMessage *message = [WXMediaMessage message];
    [message setThumbImage:thumbImage];
    
    WXImageObject *imageObject = [WXImageObject object];
    imageObject.imageData = UIImagePNGRepresentation(image);
    message.mediaObject = imageObject;
    
    [self sendToWechatWithBText:NO message:message scene:type];
}

- (void)shareToWechatWithMusicTitle:(NSString *)title description:(NSString *)description thumbImage:(UIImage *)thumbImage musicUrl:(NSString *)musicUrl musicDataUrl:(NSString *)musicDataUrl type:(NSUInteger)type {
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    [message setThumbImage:thumbImage];
    
    WXMusicObject *ext = [WXMusicObject object];
    ext.musicUrl = musicUrl;
    ext.musicLowBandUrl = ext.musicUrl;
    ext.musicDataUrl = musicDataUrl;
    ext.musicLowBandDataUrl = ext.musicDataUrl;
    message.mediaObject = ext;
    
    [self sendToWechatWithBText:NO message:message scene:type];
}

- (void)shareToWechatWithVideoTitle:(NSString *)title description:(NSString *)description thumbImage:(UIImage *)thumbImage videoUrl:(NSString *)videoUrl type:(NSUInteger)type {
    
    WXVideoObject *videoObject = [WXVideoObject object];
    videoObject.videoUrl = videoUrl;
    //低分辨了的视频url
    videoObject.videoLowBandUrl = videoObject.videoUrl;
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    [message setThumbImage:thumbImage];
    message.mediaObject = videoObject;
    [self sendToWechatWithBText:NO message:message scene:type];
}

- (void)shareToWechatWithWebTitle:(NSString *)title description:(NSString *)description thumbImage:(UIImage *)thumbImage webpageUrl:(NSString *)webpageUrl type:(NSUInteger)type {
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    [message setThumbImage:thumbImage];
    
    WXWebpageObject *webpageObject = [WXWebpageObject object];
    webpageObject.webpageUrl = webpageUrl;
    message.mediaObject = webpageObject;
    
    [self sendToWechatWithBText:NO message:message scene:type];
}

/**
 * 发送请求给微信
 * bText: 发送的消息类型
 * message: 多媒体消息结构体
 * scene: 分享的类型场景
 **/
- (void)sendToWechatWithBText:(BOOL)bText message:(WXMediaMessage *)message scene:(NSUInteger)scene {
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc]init];
    req.bText = bText;
    req.message = message;
    req.scene = (int)scene;
    
    [WXApi sendReq:req];
}
@end
