//
//  PController.m
//  Pneumonia
//
//  Created by GreySyntax and GRMrGecko on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import "PController.h"
#import "PAddons.h"
#import "USBDevice.h"

NSString * const PExtract = @"extract";
NSString * const PApplicationSupport = @"~/Library/Application Support/Pneumonia/";

//Bundle Keys
NSString * const PBName = @"name";
NSString * const PBID = @"id";
NSString * const PBFirmwares = @"firmwares";
NSString * const PBStock = @"stock";
NSString * const PBCustom = @"custom";
NSString * const PBMD5 = @"md5";
NSString * const PBFVersion = @"version";
NSString * const PBFiles = @"files";
NSString * const PBPatch = @"patch";
NSString * const PBIV = @"iv";
NSString * const PBKey = @"key";
NSString * const PBTarget = @"target";
NSString * const PBPath = @"path";
NSString * const PBEncrypt = @"encrypt";
NSString * const PBTransfer = @"transfer";
NSString * const PBMode = @"mode";
NSString * const PBFile = @"file";
NSString * const PBLocation = @"location";
NSString * const PBExploit = @"exploit";
NSString * const PBCommand = @"command";
NSString * const PBSleep = @"sleep";

//Choose Info
NSString * const PCISender = @"sender";
NSString * const PCIFile = @"file";
NSString * const PCIDeviceMatchError = @"The devices does not match";
NSString * const PCIDeviceFoundError = @"This device is not supported";
NSString * const PCIDeviceFirmwareError = @"This firmware matches the other";
NSString * const PCIDeviceFirmwareFoundError = @"This firmware is not supported";
NSString * const PCIDeviceFirmwareValidationError = @"This firmware is not valid";

//Gets rid of build warnings
@protocol NSFileManagerProtocol <NSObject>
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error;
- (BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes;

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)removeFileAtPath:(NSString *)path handler:(id)handler;

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
- (BOOL)copyPath:(NSString *)source toPath:(NSString *)destination handler:(id)handler;

- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
- (BOOL)movePath:(NSString *)source toPath:(NSString *)destination handler:(id)handler;
@end


@implementation PController
- (void)awakeFromNib {
	printf("Pneumonia - Copyright NSPwn.com - Application by GreySyntax & GRMrGecko\n\n");
	devicesDic = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Devices" ofType:@"plist"]] retain];
	
	NSFileManager<NSFileManagerProtocol> *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:[PApplicationSupport stringByExpandingTildeInPath]]) {
		if ([manager respondsToSelector:@selector(createDirectoryAtPath:attributes:)]) {
			[manager createDirectoryAtPath:[PApplicationSupport stringByExpandingTildeInPath] attributes:nil];
		} else {
			[manager createDirectoryAtPath:[PApplicationSupport stringByExpandingTildeInPath] withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}
	
	[S1Next setEnabled:NO];
	[stepsView selectTabViewItem:[stepsView tabViewItemAtIndex:0]];
}
- (void)dealloc {
	if (devicesDic!=nil)
		[devicesDic release];
	if (deviceDic!=nil)
		[deviceDic release];
	if (stockFirmware!=nil)
		[stockFirmware release];
	if (stockFirmwareMD5!=nil)
		[stockFirmwareMD5 release];
	if (stockFirmwareDic!=nil)
		[stockFirmwareDic release];
	if (customFirmware!=nil)
		[customFirmware release];
	if (customFirmwareMD5!=nil)
		[customFirmwareMD5 release];
	if (customFirmwareDic!=nil)
		[customFirmwareDic release];
	[super dealloc];
}

- (BOOL)isError:(NSString *)string {
	if ([string isEqual:PCIDeviceMatchError])
		return YES;
	if ([string isEqual:PCIDeviceFoundError])
		return YES;
	if ([string isEqual:PCIDeviceFirmwareError])
		return YES;
	if ([string isEqual:PCIDeviceFirmwareFoundError])
		return YES;
	if ([string isEqual:PCIDeviceFirmwareValidationError])
		return YES;
	return NO;
}

//Step 1: Firmware Select.
- (void)detectFirmware:(NSDictionary *)info {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	BOOL sender1 = ([info objectForKey:PCISender]==S1Choose1);
	NSArray *devices = [devicesDic allKeys];
	BOOL foundDevice = NO;
	BOOL foundFirmware = NO;
	for (int i=0; i<[devices count]; i++) {
		if ([[info objectForKey:PCIFile] rangeOfString:[devices objectAtIndex:i]].location!=NSNotFound) {
			foundDevice = YES;
			if (deviceDic!=nil) {
				if (![deviceDic isEqual:[devicesDic objectForKey:[devices objectAtIndex:i]]]) {
					if (sender1) {
						if (![[S1Firmware2 stringValue] isEqual:@""] && ![self isError:[S1Firmware2 stringValue]]) {
							[S1Firmware1 setStringValue:PCIDeviceMatchError];
							break;
						}
					} else {
						if (![[S1Firmware1 stringValue] isEqual:@""] && ![self isError:[S1Firmware1 stringValue]]) {
							[S1Firmware2 setStringValue:PCIDeviceMatchError];
							break;
						}
					}
				}
			}
			deviceDic = [devicesDic objectForKey:[devices objectAtIndex:i]];
			[S1Device setStringValue:[deviceDic objectForKey:PBName]];
			NSArray *firmwares = [[deviceDic objectForKey:PBFirmwares] allKeys];
			for (int f=0; f<[firmwares count]; f++) {
				if ([[info objectForKey:PCIFile] rangeOfString:[firmwares objectAtIndex:f]].location!=NSNotFound) {
					foundFirmware = YES;
					NSDictionary *firmware = [[deviceDic objectForKey:PBFirmwares] objectForKey:[firmwares objectAtIndex:f]];
					if ([[firmware objectForKey:PBStock] boolValue]) {
						if (sender1 && S1Firmware2Stock && ![[S1Firmware2 stringValue] isEqual:@""] && ![self isError:[S1Firmware2 stringValue]]) {
							[S1Firmware1 setStringValue:PCIDeviceFirmwareError];
							break;
						} else if (S1Firmware1Stock && ![[S1Firmware1 stringValue] isEqual:@""] && ![self isError:[S1Firmware1 stringValue]]) {
							[S1Firmware2 setStringValue:PCIDeviceFirmwareError];
							break;
						}
					} else {
						if (sender1 && !S1Firmware2Stock && ![[S1Firmware2 stringValue] isEqual:@""] && ![self isError:[S1Firmware2 stringValue]]) {
							[S1Firmware1 setStringValue:PCIDeviceFirmwareError];
							break;
						} else if (!S1Firmware1Stock && ![[S1Firmware1 stringValue] isEqual:@""] && ![self isError:[S1Firmware1 stringValue]]) {
							[S1Firmware2 setStringValue:PCIDeviceFirmwareError];
							break;
						}
					}
					if (sender1) {
						if ([[firmware objectForKey:PBStock] boolValue]) {
							S1Firmware1Stock = YES;
							if (stockFirmware!=nil) [stockFirmware release];
							stockFirmware = [[info objectForKey:PCIFile] retain];
							stockValid = NO;
						} else {
							S1Firmware1Stock = NO;
							if (customFirmware!=nil) [customFirmware release];
							customFirmware = [[info objectForKey:PCIFile] retain];
							customValid = NO;
						}
						[S1Firmware1 setStringValue:[[info objectForKey:PCIFile] lastPathComponent]];
						[S1Progress1 setHidden:NO];
						[S1Progress1 startAnimation:self];
						[S1Choose1 setEnabled:NO];
					} else {
						if ([[firmware objectForKey:PBStock] boolValue]) {
							S1Firmware2Stock = YES;
							if (stockFirmware!=nil) [stockFirmware release];
							stockFirmware = [[info objectForKey:PCIFile] retain];
							stockValid = NO;
						} else {
							S1Firmware2Stock = NO;
							if (customFirmware!=nil) [customFirmware release];
							customFirmware = [[info objectForKey:PCIFile] retain];
							customValid = NO;
						}
						[S1Firmware2 setStringValue:[[info objectForKey:PCIFile] lastPathComponent]];
						[S1Progress2 setHidden:NO];
						[S1Progress2 startAnimation:self];
						[S1Choose2 setEnabled:NO];
					}
					
					NSString *md5 = [[info objectForKey:PCIFile] pathMD5];
					if ([[firmware objectForKey:PBStock] boolValue]) {
						if (![md5 isEqual:[firmware objectForKey:PBMD5]]) {
							if (sender1)
								[S1Firmware1 setStringValue:PCIDeviceFirmwareValidationError];
							else
								[S1Firmware2 setStringValue:PCIDeviceFirmwareValidationError];
						} else {
							stockValid = YES;
							if (stockFirmwareMD5!=nil) [stockFirmwareMD5 release];
							stockFirmwareMD5 = [md5 retain];
							if (stockFirmwareDic!=nil) [stockFirmwareDic release];
							stockFirmwareDic = [firmware retain];
						}
					} else {
						if ([md5 isEqual:[firmware objectForKey:PBMD5]]) {
							if (sender1)
								[S1Firmware1 setStringValue:PCIDeviceFirmwareValidationError];
							else
								[S1Firmware2 setStringValue:PCIDeviceFirmwareValidationError];
						} else {
							customValid = YES;
							if (customFirmwareMD5!=nil) [customFirmwareMD5 release];
							customFirmwareMD5 = [md5 retain];
							if (customFirmwareDic!=nil) [customFirmwareDic release];
							customFirmwareDic = [firmware retain];
						}
					}
					
					if (sender1) {
						[S1Progress1 stopAnimation:self];
						[S1Progress1 setHidden:YES];
						[S1Choose1 setEnabled:YES];
					} else {
						[S1Progress2 stopAnimation:self];
						[S1Progress2 setHidden:YES];
						[S1Choose2 setEnabled:YES];
					}
				}
			}
			if (!foundFirmware) {
				if (sender1)
					[S1Firmware1 setStringValue:PCIDeviceFirmwareFoundError];
				else
					[S1Firmware2 setStringValue:PCIDeviceFirmwareFoundError];
			}
		}
	}
	if (!foundDevice) {
		if (sender1)
			[S1Firmware1 setStringValue:PCIDeviceFoundError];
		else
			[S1Firmware2 setStringValue:PCIDeviceFoundError];
	} else if (foundFirmware) {
		if (customValid && stockValid) {
			[S1Next setEnabled:YES];
		}
	}
	[pool release];
}
- (IBAction)S1Choose:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:@"Choose Firmware"];
	[panel setPrompt:@"Choose"];
	[panel setAllowedFileTypes:[NSArray arrayWithObject:@"ipsw"]];
	int returnCode = [panel runModal];
	if (returnCode==NSOKButton) {
		[S1Next setEnabled:NO];
		NSString *file = [[[panel URLs] objectAtIndex:0] path];
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:sender, PCISender, file, PCIFile, nil];
		[NSThread detachNewThreadSelector:@selector(detectFirmware:) toTarget:self withObject:info];
	}
}
- (IBAction)S1Next:(id)sender {
	[S2Progress setDoubleValue:0.0];
	[stepsView selectTabViewItem:[stepsView tabViewItemAtIndex:1]];
	[S2Progress startAnimation:self];
	[NSThread detachNewThreadSelector:@selector(extractAndPatch) toTarget:self withObject:nil];
}

//Step 2: Extract and Patch Firmware.
- (void)extractAndPatch {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSFileManager<NSFileManagerProtocol> *manager = [NSFileManager defaultManager];
	NSString *extract = [[PApplicationSupport stringByExpandingTildeInPath] stringByAppendingPathComponent:PExtract];
	if ([manager fileExistsAtPath:extract]) {
		if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
			[manager removeFileAtPath:extract handler:nil];
		} else {
			[manager removeItemAtPath:extract error:nil];
		}
	}
	//Stock
	NSString *stockPath = [[PApplicationSupport stringByExpandingTildeInPath] stringByAppendingPathComponent:stockFirmwareMD5];
	if (![manager fileExistsAtPath:stockPath]) {
		if ([manager respondsToSelector:@selector(createDirectoryAtPath:attributes:)]) {
			[manager createDirectoryAtPath:stockPath attributes:nil];
		} else {
			[manager createDirectoryAtPath:stockPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		
		[S2Status setStringValue:[NSString stringWithFormat:@"Extracting %@ Firmware", [stockFirmwareDic objectForKey:PBFVersion]]];
		if (![self unzip:stockFirmware toPath:extract]) {
			NSAlert *theAlert = [[NSAlert new] autorelease];
			[theAlert addButtonWithTitle:@"Quit"];
			[theAlert setMessageText:@"Error"];
			[theAlert setInformativeText:[NSString stringWithFormat:@"Firmware %@ was unable to be extracted", [stockFirmwareDic objectForKey:PBFVersion]]];
			[theAlert setAlertStyle:NSWarningAlertStyle];
			[theAlert runModal];
			if ([manager fileExistsAtPath:extract]) {
				if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
					[manager removeFileAtPath:extract handler:nil];
				} else {
					[manager removeItemAtPath:extract error:nil];
				}
			}
			[[NSApplication sharedApplication] terminate:self];
			return;
		}
		
		[S2Progress setDoubleValue:1.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Patching %@ Firmware", [stockFirmwareDic objectForKey:PBFVersion]]];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		double increasement = 1.0/(double)[[stockFirmwareDic objectForKey:PBFiles] count];
		for (int i=0; i<[[stockFirmwareDic objectForKey:PBFiles] count]; i++) {
			NSDictionary *file = [[stockFirmwareDic objectForKey:PBFiles] objectAtIndex:i];
			
			if (![[file objectForKey:PBKey] isEqual:@""] && ![[file objectForKey:PBIV] isEqual:@""]) {
				[S2Status setStringValue:[NSString stringWithFormat:@"Decrypting %@", [file objectForKey:PBName]]];
				[self xpwnDecrypt:[extract stringByAppendingPathComponent:[file objectForKey:PBPath]]
						  newFile:[stockPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
							  key:[file objectForKey:PBKey]
							   iv:[file objectForKey:PBIV]];
			} else {
				[S2Status setStringValue:[NSString stringWithFormat:@"Copying %@", [file objectForKey:PBName]]];
				if ([manager respondsToSelector:@selector(copyPath:toPath:handler:)]) {
					[manager copyPath:[extract stringByAppendingPathComponent:[file objectForKey:PBPath]]
							   toPath:[stockPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
							  handler:nil];
				} else {
					[manager copyItemAtPath:[extract stringByAppendingPathComponent:[file objectForKey:PBPath]]
									 toPath:[stockPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
									  error:nil];
				}
			}
			
			if (![[file objectForKey:PBPatch] isEqual:@""]) {
				[S2Status setStringValue:[NSString stringWithFormat:@"Patching %@", [file objectForKey:PBName]]];
				NSString *patchFile = [[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[deviceDic objectForKey:PBID]]
										stringByAppendingPathComponent:[stockFirmwareDic objectForKey:PBID]]
									   stringByAppendingPathComponent:[file objectForKey:PBPatch]];
				
				[self bspatch:[stockPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
					  newFile:[stockPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
						patch:patchFile];
			}
			
			if ([[file objectForKey:PBEncrypt] boolValue]) {
				[S2Status setStringValue:[NSString stringWithFormat:@"Encrypting %@", [file objectForKey:PBName]]];
				//TODO xpwntool encrypt
			}
			
			[S2Progress setDoubleValue:[S2Progress doubleValue]+increasement];
		}
		
		[S2Progress setDoubleValue:2.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Cleaning %@ Firmware", [stockFirmwareDic objectForKey:PBFVersion]]];
		if ([manager fileExistsAtPath:extract]) {
			if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
				[manager removeFileAtPath:extract handler:nil];
			} else {
				[manager removeItemAtPath:extract error:nil];
			}
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	}
	
	//Custom
	NSString *customPath = [[PApplicationSupport stringByExpandingTildeInPath] stringByAppendingPathComponent:customFirmwareMD5];
	if (![manager fileExistsAtPath:customPath]) {
		if ([manager respondsToSelector:@selector(createDirectoryAtPath:attributes:)]) {
			[manager createDirectoryAtPath:customPath attributes:nil];
		} else {
			[manager createDirectoryAtPath:customPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		
		[S2Progress setDoubleValue:3.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Extracting %@ Firmware", [customFirmwareDic objectForKey:PBFVersion]]];
		if (![self unzip:customFirmware toPath:extract]) {
			NSAlert *theAlert = [[NSAlert new] autorelease];
			[theAlert addButtonWithTitle:@"Quit"];
			[theAlert setMessageText:@"Error"];
			[theAlert setInformativeText:[NSString stringWithFormat:@"Firmware %@ was unable to be extracted", [customFirmwareDic objectForKey:PBFVersion]]];
			[theAlert setAlertStyle:NSWarningAlertStyle];
			[theAlert runModal];
			if ([manager fileExistsAtPath:extract]) {
				if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
					[manager removeFileAtPath:extract handler:nil];
				} else {
					[manager removeItemAtPath:extract error:nil];
				}
			}
			[[NSApplication sharedApplication] terminate:self];
			return;
		}
		
		[S2Progress setDoubleValue:4.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Patching %@ Firmware", [customFirmwareDic objectForKey:PBFVersion]]];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		double increasement = 1.0/(double)[[customFirmwareDic objectForKey:PBFiles] count];
		for (int i=0; i<[[customFirmwareDic objectForKey:PBFiles] count]; i++) {
			NSDictionary *file = [[customFirmwareDic objectForKey:PBFiles] objectAtIndex:i];
			
			if (![[file objectForKey:PBKey] isEqual:@""] && ![[file objectForKey:PBIV] isEqual:@""]) {
				[S2Status setStringValue:[NSString stringWithFormat:@"Decrypting %@", [file objectForKey:PBName]]];
				[self xpwnDecrypt:[extract stringByAppendingPathComponent:[file objectForKey:PBPath]]
						  newFile:[customPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
							  key:[file objectForKey:PBKey]
							   iv:[file objectForKey:PBIV]];
			} else {
				[S2Status setStringValue:[NSString stringWithFormat:@"Copying %@", [file objectForKey:PBName]]];
				if ([manager respondsToSelector:@selector(copyPath:toPath:handler:)]) {
					[manager copyPath:[extract stringByAppendingPathComponent:[file objectForKey:PBPath]]
							   toPath:[customPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
							  handler:nil];
				} else {
					[manager copyItemAtPath:[extract stringByAppendingPathComponent:[file objectForKey:PBPath]]
									 toPath:[customPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
									  error:nil];
				}
			}
			
			if (![[file objectForKey:PBPatch] isEqual:@""]) {
				[S2Status setStringValue:[NSString stringWithFormat:@"Patching %@", [file objectForKey:PBName]]];
				NSString *patchFile = [[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[deviceDic objectForKey:PBID]]
										stringByAppendingPathComponent:[customFirmwareDic objectForKey:PBID]]
									   stringByAppendingPathComponent:[file objectForKey:PBPatch]];
				
				[self bspatch:[customPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
					  newFile:[customPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
						patch:patchFile];
			}
			
			if ([[file objectForKey:PBEncrypt] boolValue]) {
				[S2Status setStringValue:[NSString stringWithFormat:@"Encrypting %@", [file objectForKey:PBName]]];
				//TODO xpwntool encrypt
			}
			
			[S2Progress setDoubleValue:[S2Progress doubleValue]+increasement];
		}
		
		[S2Progress setDoubleValue:5.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Cleaning %@ Firmware", [customFirmwareDic objectForKey:PBFVersion]]];
		if ([manager fileExistsAtPath:extract]) {
			if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
				[manager removeFileAtPath:extract handler:nil];
			} else {
				[manager removeItemAtPath:extract error:nil];
			}
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	}
	
	//Add firmware to previous firmwares for reloading later.
	NSMutableArray *firmwares;
	if ([[NSUserDefaults standardUserDefaults] objectForKey:PBFirmwares]) {
		firmwares = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:PBFirmwares]];
	} else {
		firmwares = [NSMutableArray array];
	}
	BOOL shouldSave = YES;
	for (int i=0; i<[firmwares count]; i++) {
		if ([[[[firmwares objectAtIndex:i] objectForKey:PBStock] objectForKey:PBMD5] isEqual:stockFirmwareMD5] &&
			[[[[firmwares objectAtIndex:i] objectForKey:PBCustom] objectForKey:PBMD5] isEqual:customFirmwareMD5])
			shouldSave = NO;
	}
	if (shouldSave) {
		NSDictionary *stock = [NSDictionary dictionaryWithObjectsAndKeys:[stockFirmwareDic objectForKey:PBFVersion], PBFVersion, [stockFirmwareDic objectForKey:PBID], PBID, stockFirmwareMD5, PBMD5, nil];
		NSDictionary *custom = [NSDictionary dictionaryWithObjectsAndKeys:[customFirmwareDic objectForKey:PBFVersion], PBFVersion, [customFirmwareDic objectForKey:PBID], PBID, customFirmwareMD5, PBMD5, nil];
		NSDictionary *firmwareInfo = [NSDictionary dictionaryWithObjectsAndKeys:[deviceDic objectForKey:PBName], PBName, [deviceDic objectForKey:PBID], PBID, stock, PBStock, custom, PBCustom, nil];
		
		[firmwares addObject:firmwareInfo];
		[[NSUserDefaults standardUserDefaults] setObject:firmwares forKey:PBFirmwares];
	}
	
	[S2Progress setDoubleValue:6.0];
	[S2Status setStringValue:@"Done"];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	[self performSelectorOnMainThread:@selector(S2Continue) withObject:nil waitUntilDone:NO];
	
	[pool release];
}
- (void)S2Continue {
	[stepsView selectTabViewItem:[stepsView tabViewItemAtIndex:2]];
}

//Step 3: Boot or Prepare Device
- (IBAction)S3Boot:(id)sender {
	[S3Progress setDoubleValue:0.0];
    [S3Info setStringValue:[NSString stringWithFormat:@"Booting %@, please wait...", [deviceDic objectForKey:PBName]]];
	[S3Progress startAnimation:self];
	[stepsView selectTabViewItem:[stepsView tabViewItemAtIndex:3]];
	[NSThread detachNewThreadSelector:@selector(S3Run:) toTarget:self withObject:@"boot"];
}
- (IBAction)S3Prepare:(id)sender {
	[S3Progress setDoubleValue:0.0];
    [S3Info setStringValue:[NSString stringWithFormat:@"Preparing %@ for restore, please wait...", [deviceDic objectForKey:PBName]]];
	[S3Progress startAnimation:self];
	[stepsView selectTabViewItem:[stepsView tabViewItemAtIndex:3]];
	[NSThread detachNewThreadSelector:@selector(S3Run:) toTarget:self withObject:@"prepare"];
}
- (void)S3Run:(NSString *)theSet {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSString *stockPath = [[PApplicationSupport stringByExpandingTildeInPath] stringByAppendingPathComponent:stockFirmwareMD5];
	NSString *customPath = [[PApplicationSupport stringByExpandingTildeInPath] stringByAppendingPathComponent:customFirmwareMD5];
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSArray *set = [[[stockFirmwareDic objectForKey:PBTransfer] objectForKey:[customFirmwareDic objectForKey:PBID]] objectForKey:theSet];
	
	//iBootUSBConnection iDev = NULL;
	//USBDevice usbDevice;
    [S3Progress setMaxValue:(([set count]-1)*2)+1];
    S3ProgressCount = -1;
	int mode = 0;
	for (int i=0; i<[set count]; i++) {
		NSDictionary *item = [set objectAtIndex:i];
		BOOL status = 0;
		
		if (mode!=[[item objectForKey:PBMode] intValue]) {
			usbDevice.Disconnect();
		}
		mode = [[item objectForKey:PBMode] intValue];
		
		if (!usbDevice.IsConnected() && mode!=0 && !usbDevice.Connect()) {
			NSLog(@"Unable to connect to iDevice");
			break;
		}
		
        S3ProgressCount++;
        [S3Progress setDoubleValue:S3ProgressCount];
		if (![[item objectForKey:PBFile] isEqual:@""]) {
            [S3Status setStringValue:[NSString stringWithFormat:@"Sending %@", [item objectForKey:PBFile]]];
			NSString *path = [resourcePath stringByAppendingPathComponent:[item objectForKey:PBFile]];
			if ([[item objectForKey:PBLocation] isEqual:PBStock]) {
                path = [stockPath stringByAppendingPathComponent:[item objectForKey:PBFile]];
            } else if ([[item objectForKey:PBLocation] isEqual:PBCustom]) {
                path = [customPath stringByAppendingPathComponent:[item objectForKey:PBFile]];
            }
            
            NSLog(@"Sending %@", path);
			if ([[item objectForKey:PBExploit] boolValue])
				status = usbDevice.Exploit([path UTF8String]);
			else
				status = usbDevice.Upload([path UTF8String]);
			if (!status) {
				NSLog(@"While sending %@, we got the status %d", path, status);
			}
		}
		
        S3ProgressCount++;
        [S3Progress setDoubleValue:S3ProgressCount];
		if (![[item objectForKey:PBCommand] isEqual:@""]) {
            [S3Status setStringValue:[NSString stringWithFormat:@"Running %@", [item objectForKey:PBCommand]]];
			status = usbDevice.SendCommand([[item objectForKey:PBCommand] UTF8String]);
			if (!status) {
				NSLog(@"While running %@, we got the status %d", [item objectForKey:PBCommand], status);
			}
		}
		
		if ([[item objectForKey:PBSleep] intValue] > 0) {
			[NSThread sleepForTimeInterval:[[item objectForKey:PBSleep] intValue]];
		}
	}
	S3ProgressCount++;
	[S3Progress setDoubleValue:S3ProgressCount];
	[S3Status setStringValue:@"Done"];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	[self performSelectorOnMainThread:@selector(S2Continue) withObject:nil waitUntilDone:NO];
	[pool release];
}

//Utilities
- (BOOL)unzip:(NSString *)path toPath:(NSString *)toPath {
	BOOL result = YES;

	//If we really wanted to, we can set up a NSPipe here and make it show progress.
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:@"/usr/bin/unzip"];
	[theTask setCurrentDirectoryPath:[@"~/" stringByExpandingTildeInPath]];
	[theTask setArguments:[NSArray arrayWithObjects:@"-o", path, @"-d", toPath, nil]];
	[theTask launch];
	[theTask waitUntilExit];
	result = ([theTask terminationStatus]==0);
	[theTask release];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	
	return result;
}

- (BOOL)xpwnDecrypt:(NSString *)file newFile:(NSString *)newFile key:(NSString *)key iv:(NSString *)iv {
	BOOL result = YES;
	
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"xpwntool" ofType:@""]];
	[theTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	[theTask setArguments:[NSArray arrayWithObjects:file, newFile, @"-k", key, @"-iv", iv, nil]];
	[theTask launch];
	[theTask waitUntilExit];
	result = ([theTask terminationStatus] == 0);
	[theTask release];
	
	return result;
}

- (BOOL)bspatch:(NSString *)file newFile:(NSString *)newFile patch:(NSString *)patch {
	BOOL result = YES;
	
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:@"/usr/bin/bspatch"];
	[theTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	[theTask setArguments:[NSArray arrayWithObjects:file, newFile, patch, nil]];
	[theTask launch];
	[theTask waitUntilExit];
	result = ([theTask terminationStatus] == 0);
	[theTask release];
	
	return result;
}
@end