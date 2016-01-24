//
//  QLAudioDebugMacros.h
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/23.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#ifndef QLAudioDebugMacros_h
#define QLAudioDebugMacros_h

#include <stdio.h>

#define LOGSWITCH 1


#if DEBUG && LOGSWITCH
    #define QLAudioDebugPrintf      fprintf
    #define QLAudioPrintfFileComma  stderr
    #define	QLAudioPrintfLineEnding	"\n"

    #define QLAudioDebugMsg(msg)        QLAudioDebugPrintf(QLAudioPrintfFileComma,"%s" QLAudioPrintfLineEnding, msg)
    #define QLAudioDebugMsgN1(msg,N1)   QLAudioDebugPrintf(QLAudioPrintfFileComma,msg QLAudioPrintfLineEnding,N1)
    #define QLAudioDebugMsgN2(msg,N1,N2)   QLAudioDebugPrintf(QLAudioPrintfFileComma,msg QLAudioPrintfLineEnding,N1,N2)
#else

    #define QLAudioDebugPrintf

    #define QLAudioDebugMsg(msg)

#endif

#endif /* QLAudioDebugMacros_h */
