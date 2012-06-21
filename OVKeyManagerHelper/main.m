//
//  main.m
//  OVKeyManagerHelper
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//


/*
 
 File: SMJobBlessHelper.c
 Abstract: A helper tool that doesn't do anything event remotely interesting.
 See the ssd sample for how to use GCD and launchd to set up an on-demand
 server via sockets.
 Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 
 */

#include <syslog.h>
#include <xpc/xpc.h>
#import <Cocoa/Cocoa.h>

#import "PHCErrors.h"
#import "OVKeyManagerHelperAPI.h"

void reply_failure(xpc_object_t event, NSError *err, xpc_connection_t remote) {
    xpc_object_t reply = xpc_dictionary_create_reply(event);
    xpc_dictionary_set_bool(reply, RESULT_STATUS_KEY, false);
    xpc_dictionary_set_string(reply, RESULT_ERR_MSG_KEY, [[err localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
    xpc_connection_send_message(remote, reply);
    xpc_release(reply);
}

void reply_success(xpc_object_t event, xpc_connection_t remote) {
    xpc_object_t reply = xpc_dictionary_create_reply(event);
    xpc_dictionary_set_bool(reply, RESULT_STATUS_KEY, true);
    xpc_connection_send_message(remote, reply);
    xpc_release(reply);
}

void handle_add_key_command(xpc_object_t event, xpc_connection_t remote) {
    
    NSString *sharedKey = [NSString stringWithCString:xpc_dictionary_get_string(event, SHARED_ENCRYPTION_KEY_KEY)
                                             encoding:NSUTF8StringEncoding];
    
    NSString * keyID = [NSString stringWithCString:xpc_dictionary_get_string(event, KEY_ID_KEY)
                                          encoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    const char * service = "com.physionconsulting.ovation";
    NSString * ooqsPath = @"/opt/object/mac86_64/bin/ooqs";
    
    if(writeKey(service, 
                [keyID cStringUsingEncoding:NSUTF8StringEncoding], 
                [sharedKey cStringUsingEncoding:NSUTF8StringEncoding],
                [NSArray arrayWithObject:ooqsPath],
                &err)) {
        
        
        syslog(LOG_NOTICE, "Sucesfully added key to system key chain");  
        
        reply_success(event, remote);
        
    } else {
        syslog(LOG_ERR, "Unable to add key to system key chain");
        
        reply_failure(event, err, remote);
    }
}

static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
    
	xpc_type_t type = xpc_get_type(event);
    
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
            
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
        
	} else {
        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
        
        NSString *command = [NSString stringWithCString:xpc_dictionary_get_string(event, COMMAND_KEY)
                                               encoding:NSUTF8StringEncoding];
        
        if([command isEqualToString:[NSString stringWithCString:ADD_KEY_COMMAND 
                                                       encoding:NSUTF8StringEncoding]]) {
            
            handle_add_key_command(event, remote);
        
        } else if([command isEqualToString:@"get-keys"]) {
            
        } else {
            syslog(LOG_ERR, "OVKeyManager helper received an uknown command: %s", [command cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        
	}
}


static void __XPC_Connection_Handler(xpc_connection_t connection)  {
    syslog(LOG_NOTICE, "Configuring message event handler for OVKeyManager helper.");
    
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		__XPC_Peer_Event_Handler(connection, event);
	});
	
	xpc_connection_resume(connection);
}

int main(int argc, const char *argv[]) {
    
    syslog(LOG_NOTICE, "Starting OVKeyManagerHelper service");
    
    xpc_connection_t service = xpc_connection_create_mach_service("com.physionconsulting.OVKeyManagerHelper",
                                                                  dispatch_get_main_queue(),
                                                                  XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    if (!service) {
        syslog(LOG_NOTICE, "Failed to create OVKeyManagerHelper service.");
        exit(EXIT_FAILURE);
    }
    
    syslog(LOG_NOTICE, "Configuring connection event handler for OVKeyManager helper");
    xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
        __XPC_Connection_Handler(connection);
    });
    
    xpc_connection_resume(service);
    
    dispatch_main();
    
    xpc_release(service);
    
    return EXIT_SUCCESS;
}


