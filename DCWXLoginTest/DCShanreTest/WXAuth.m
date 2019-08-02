//
//  WXAuth.m
//  hongyantub2b
//
//  Created by Apple on 2018/8/23.
//  Copyright © 2018年 Apple. All rights reserved.
//

#import "WXAuth.h"
#import "WXApi.h"

#define WXAppId            @"wx7a375905493d4be9"//填上应用的AppID

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
- (NSString *)getWXAppId{
    return WXAppId;
}

- (void)loginWXAuthReq{
    
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
        
        //调用微信回调代理
        return [WXApi handleOpenURL:url delegate:self];
    }else{
        
        return NO;
    }
}

/**
 Delegate回调方法
 */
- (void)onResp:(BaseResp *)resp{
    if([resp isKindOfClass:[SendAuthResp class]]){//判断是否为授权登录类
        
        SendAuthResp *req = (SendAuthResp *)resp;
        if([req.state isEqualToString:@"wx_oauth_authorization_state"]){//微信授权成功
            
            if(req.errCode == 0){
                
                NSLog(@"获取code：%@", req.code);
                [self get:req.code completion:^(NSDictionary *dictionary) {
                    NSLog(@"%@",dictionary);
                    
                    //获取access_token
                    NSString *access_token = dictionary[@"access_token"];
                    //获取openid
                    NSString *openid = dictionary[@"openid"];
                    
                    [self getAccess_token:access_token openId:openid completion:^(NSDictionary *dictionary) {
                        NSLog(@"%@",dictionary);
                        
                    }];

                }];
                
//                req.code;
            }
        }
    }
    if([resp isKindOfClass:[SendMessageToWXResp class]]){
        
        SendMessageToWXResp *req = (SendMessageToWXResp *)resp;
        //这里不再返回用户是否分享完成事件，即原先的cancel事件和success事件将统一为success事件
        if(req.errCode == 0){
            NSLog(@"分享成功");
        }
    }
    
    if([resp isKindOfClass:[PayResp class]]){
        switch (resp.errCode) {
            case WXSuccess:{
                NSLog(@"支付成功");
            }
                break;
            default:{
                NSLog(@"支付失败:%d",resp.errCode);
            }
            break;
        }
    }
}

/**
 通过回调代理code 获取openid 方法
 */
- (void)get:(NSString *)code completion:(void (^)(NSDictionary *))completion
{
    NSString *urlStr = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=wx7a375905493d4be9&secret=b923f78beab716e42ed8be588790e3d3&code=%@&grant_type=authorization_code",code];
    // 获得NSURLSession对象
    NSURLSession *session = [NSURLSession sharedSession];
    
    // 创建任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        completion(dictionary);
     /*
        {
            "access_token":"ACCESS_TOKEN", //接口调用凭证
            "expires_in":7200, //access_token接口调用凭证超时时间，单位（秒）
            "refresh_token":"REFRESH_TOKEN", //用户刷新access_token
            "openid":"OPENID", //授权用户唯一标识
            "scope":"SCOPE", //用户授权的作用域，使用逗号（,）分隔
            "unionid":"o6_bmasdasdsad6_2sgVt7hMZOPfL" //当且仅当该移动应用已获得该用户的userinfo授权时，才会出现该字段
        }
      */
    }];
    
    // 启动任务
    [task resume];
}

/** 获取用户的信息的方法 */
- (void)getAccess_token:(NSString *)access_token openId:(NSString *)openId completion:(void (^)(NSDictionary *))completion
{
    NSString *urlStr = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",access_token,openId];
    // 获得NSURLSession对象
    NSURLSession *session = [NSURLSession sharedSession];
    
    // 创建任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        completion(dictionary);
        NSLog(@"微信用户名：%@",dictionary[@"nickname"]);
        /*
         {
         "openid":"OPENID", //用户的标识，对当前开发者帐号唯一
         "nickname":"NICKNAME", //用户昵称
         "sex":1, //用户性别，1为男性，2为女性
         "province":"PROVINCE", //用户个人资料填写的省份
         "city":"CITY", //用户个人资料填写的城市
         "country":"COUNTRY", //国家，如中国为CN
         "headimgurl": "http://wx.qlogo.cn/mmopen/g3MonUZtNHkdmzicIlibx6iaFqAc56vxLSUfpb6n5WKSYVY0ChQKkiaJSgQ1dZuTOgvLLrhJbERQQ4eMsv84eavHiaiceqxibJxCfHe/0", //用户头像，最后一个数值代表正方形头像大小（有0、46、64、96、132数值可选，0代表640*640正方形头像），用户没有头像时该项为空
         "unionid": " o6_bmasdasdsad6_2sgVt7hMZOPfL" //用户统一标识。针对一个微信开放平台帐号下的应用，同一用户的unionid是唯一的。
         }
         */
    }];
    
    // 启动任务
    [task resume];
}


/** 跳转到微信支付 */
- (void)jumpToBizPay{
    
    if(![WXApi isWXAppInstalled]){//判断当前设备是否安装微信客户端
        //未安装微信应用或版本过低
        NSLog(@"未安装微信应用或版本过低");
        return;
    }
    
    // 调起微信支付
    PayReq *request = [[PayReq alloc] init];
    /** 微信分配的公众账号ID -> APPID */
    request.partnerId = WXAppId;
    /** 预支付订单 从服务器获取 */
    request.prepayId = @"1101000000140415649af9fc314aa427";
    /** 商家根据财付通文档填写的数据和签名 <暂填写固定值Sign=WXPay>*/
    request.package = @"Sign=WXPay";
    /** 随机串，防重发 */
    request.nonceStr= @"a462b76e7436e98e0ed6e13c64b4fd1c";
    /** 时间戳，防重发 */
    request.timeStamp= 1397527777;
    /** 商家根据微信开放平台文档对数据做的签名, 可从服务器获取，也可本地生成*/
    request.sign= @"582282D72DD2B03AD892830965F428CB16E7A256";
    /* 调起支付 */
    [WXApi sendReq:request];

}

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
