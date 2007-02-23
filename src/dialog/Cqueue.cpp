/*
 * Copyright (c) 2002-2006 Milan Cutka
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "stdafx.h"
#include "Cqueue.h"
#include "TvideoCodec.h"
#include "CquantTables.h"

void TqueuePage::init(void)
{
 edLimitText(IDC_ED_USE_QUEUE_ONLY_IN_LIST,256);
}

void TqueuePage::cfg2dlg(void)
{
 setCheck(IDC_CHB_MULTITHREAD,cfgGet(IDFF_multiThreadDec));
 setCheck(IDC_CHB_USE_QUEUE_ONLY_IN,cfgGet(IDFF_useQueueOnlyIn));
 SetDlgItemText(m_hwnd,IDC_ED_USE_QUEUE_ONLY_IN_LIST,cfgGetStr(IDFF_useQueueOnlyInList));
 delay2dlg();
 interlaced2dlg();
}
void TqueuePage::delay2dlg(void)
{
 SetDlgItemInt(m_hwnd,IDC_ED_VIDEODELAY,cfgGet(IDFF_videoDelay),TRUE);
 int isEnd=cfgGet(IDFF_isVideoDelayEnd);
 static const int ends[]={IDC_ED_VIDEODELAYEND,IDC_LBL_VIDEODELAYEND_MS,0};
 enable(isEnd,ends);
 setCheck(IDC_CHB_VIDEODELAYEND,isEnd);
 SetDlgItemInt(m_hwnd,IDC_ED_VIDEODELAYEND,cfgGet(IDFF_videoDelayEnd),TRUE);
 setDlgItemText(m_hwnd,IDC_LBL_VIDEODELAYSTART,_(IDC_LBL_VIDEODELAYSTART,isEnd?_l("start"):_l("constant")));
}
void TqueuePage::interlaced2dlg(void)
{
 setCheck(IDC_CHB_DY_INTERLACED,cfgGet(IDFF_isDyInterlaced));
 SetDlgItemInt(m_hwnd,IDC_ED_DY_INTERLACED,cfgGet(IDFF_dyInterlaced),FALSE);
 enable(cfgGet(IDFF_isDyInterlaced),IDC_ED_DY_INTERLACED);
}

INT_PTR TqueuePage::msgProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
{
 switch (uMsg)
  {
   case WM_COMMAND:
    switch (LOWORD(wParam))
     {
      case IDC_ED_USE_QUEUE_ONLY_IN_LIST:
       if (HIWORD(wParam)==EN_CHANGE && !isSetWindowText)
        {
         char_t applist[256];
         GetDlgItemText(m_hwnd,IDC_ED_USE_QUEUE_ONLY_IN_LIST,applist,256);
         cfgSet(IDFF_useQueueOnlyInList,applist);
        }
       return TRUE;
     }
   break;
  }
 return TconfPageDecVideo::msgProc(uMsg,wParam,lParam);
}

bool TqueuePage::reset(bool testonly)
{
 if (!testonly)
  {
   deci->resetParam(IDFF_videoDelay);
   deci->resetParam(IDFF_multiThreadDec);
   deci->resetParam(IDFF_useQueueOnlyIn);
  }
 return true;
}

void TqueuePage::translate(void)
{
 TconfPageBase::translate();
}

void TqueuePage::getTip(char_t *tipS,size_t len)
{
 if (cfgGet(IDFF_videoDelay)) strcatf(tipS,_l("\nVideo delay: %i msec"),cfgGet(IDFF_videoDelay));
}

TqueuePage::TqueuePage(TffdshowPageDec *Iparent):TconfPageDecVideo(Iparent)
{
 dialogId=IDD_QUEUE;
 inPreset=1;
 idffOrder=maxOrder+2;
 static const TbindCheckbox<TqueuePage> chb[]=
  {
   IDC_CHB_VIDEODELAYEND,IDFF_isVideoDelayEnd,&TqueuePage::delay2dlg,
   IDC_CHB_DY_INTERLACED,IDFF_isDyInterlaced,&TqueuePage::interlaced2dlg,
   IDC_CHB_MULTITHREAD,IDFF_multiThreadDec,NULL,
   IDC_CHB_USE_QUEUE_ONLY_IN,IDFF_useQueueOnlyIn,NULL,
   0,NULL,NULL
  };
 bindCheckboxes(chb);
 static const TbindEditInt<TqueuePage> edInt[]=
  {
   IDC_ED_VIDEODELAY,INT_MIN/2,INT_MAX/2,IDFF_videoDelay,NULL,
   IDC_ED_VIDEODELAYEND,INT_MIN/2,INT_MAX/2,IDFF_videoDelayEnd,NULL,
   IDC_ED_DY_INTERLACED,0,4096,IDFF_dyInterlaced,NULL,
   0,NULL,NULL
  };
 bindEditInts(edInt);
}
