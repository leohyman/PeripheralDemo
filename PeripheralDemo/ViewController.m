//
//  ViewController.m
//  PeripheralDemo
//
//  Created by lvzhao on 2020/4/9.
//  Copyright © 2020 lvzhao. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>




//打开终端 uuidgen 即可生成
#define SERVICE_UUID @"8D54ECDE-7A78-4B62-9F44-780A0588B5CE"
#define CHARACTERISTIC_UUID @"04392C1C-00AF-4A29-B8BB-E02CEEC52C43"
@interface ViewController ()<CBPeripheralDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}


/*
 *检测蓝牙的状态
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    
    switch (peripheral.state) {
        case CBManagerStatePoweredOn:
        {
            NSLog(@"蓝牙状态OK");
            // 配置Service（服务）和Characteristics（特征）
            [self configServiceAndCharacteristics];
            // 根据服务的UUID开始广播
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:SERVICE_UUID]]}];
            
        }
            break;
            
        default:
            NSLog(@"蓝牙状态不对, 请检查");
            break;
    }
    
    
}


/**
 配置Service（服务）和Characteristics（特征）
 */
- (void)configServiceAndCharacteristics{
    
    //创建服务
    CBUUID *serviceID  = [CBUUID UUIDWithString:SERVICE_UUID];
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceID primary:YES];
    //创建服务中的特征
    CBUUID *characteristicID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicID
                                                                                 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify
                                                                                      value:nil
                                                                                permissions:CBAttributePermissionsReadable| CBAttributePermissionsWriteable];
    
    //特征添加到服务里面
    service.characteristics = @[characteristic];
    //服务添加到管理
    [self.peripheralManager addService:service];
    
    
    //是否手动发送消息 .不用的话就可以不写
    self.characteristic = characteristic;
}


/**
 订阅成功回调
 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"订阅成功%s",__func__);
}

/**
 取消订阅回调
 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"%s",__func__);
}
/**
 中心设备读取数据的时候回调
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    // 请求中的数据，这里把文本框中的数据发给中心设备
    request.value = [self.textField.text dataUsingEncoding:NSUTF8StringEncoding];
    // 成功响应请求
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

/**
 中心设备写入数据的时候回调
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    // 写入数据的请求
    CBATTRequest *request = requests.lastObject;
    // 把写入的数据显示在文本框中
    self.textField.text = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
}

- (IBAction)sendDataAcrion:(id)sender {
    
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(timerSendMessage) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];

}

- (void)timerSendMessage{
    
    BOOL sendSuccess = [self.peripheralManager updateValue:[self.textField.text dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
    if (sendSuccess) {
        NSLog(@"数据发送成功");
    }else {
        NSLog(@"数据发送失败");
    }
}

@end
