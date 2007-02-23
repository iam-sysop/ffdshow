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
#include "Coutcsps.h"
#include "Tlibavcodec.h"
#include "ToutputVideoSettings.h"
#include "Ttranslate.h"

const int ToutcspsPage::idcs []={IDC_CHB_OUT_I420,IDC_CHB_OUT_YV12,IDC_CHB_OUT_YUY2,IDC_CHB_OUT_YVYU,IDC_CHB_OUT_UYVY,IDC_CHB_OUT_NV12,IDC_CHB_OUT_RGB32,IDC_CHB_OUT_RGB24,IDC_CHB_OUT_RGB15,IDC_CHB_OUT_RGB16,0};
const int ToutcspsPage::idffs[]={IDFF_outI420    ,IDFF_outYV12    ,IDFF_outYUY2    ,IDFF_outYVYU    ,IDFF_outUYVY    ,IDFF_outNV12    ,IDFF_outRGB32    ,IDFF_outRGB24    ,IDFF_outRGB555   ,IDFF_outRGB565   };

void ToutcspsPage::init(void)
{
 Tlibavcodec *lavc;
 deci->getLibavcodec(&lavc);
 static const int dvs[]={IDC_CHB_OUT_DV,IDC_LBL_OUT_DV_PROFILE,IDC_CBX_OUT_DV_PROFILE,0};
 enable(lavc && lavc->ok && !lavc->dec_only && (filterMode&IDFF_FILTERMODE_VFW)==0,dvs);
 if (lavc) lavc->Release();
 if(tr)
  {
   addHint(IDC_CHB_HWOVERLAY,tr->translate(IDH_HWOVERLAY));
   addHint(IDC_CHB_ALLOWOUTCHANGE,tr->translate(IDH_ALLOWOUTCHANGE));
   addHint(IDC_CHB_OUTCHANGECOMPATONLY,tr->translate(IDH_OUTCHANGECOMPATONLY));
   addHint(IDC_CBX_OUT_HWDEINT_METHOD,tr->translate(IDH_HWDEINT));
   addHint(IDC_CHB_HWDEINTERLACE,tr->translate(IDH_HWDEINT));
  }
}
void ToutcspsPage::cfg2dlg(void)
{
 dv2dlg();
 csp2dlg();
 setCheck(IDC_CHB_FLIP,cfgGet(IDFF_flip));
 overlay2dlg();
 dfc2dlg();
}
void ToutcspsPage::dv2dlg(void)
{
 int is=cfgGet(IDFF_outDV);
 if (is && !enabled(IDC_CHB_OUT_DV) && (filterMode&IDFF_FILTERMODE_VFW)==0)
  {
   cfgSet(IDFF_outDV,is=0);
   cfgSet(IDFF_outYV12,1);
  }
 setCheck(IDC_CHB_OUT_DV,is);
 static const int dvs[]={IDC_LBL_OUT_DV_PROFILE,IDC_CBX_OUT_DV_PROFILE,0};
 enable(is,dvs);
 static const int raws[]={IDC_CHB_OUT_CLOSESTMATCH,IDC_CHB_HWDEINTERLACE,IDC_CHB_ALLOWOUTCHANGE,IDC_CHB_OUTCHANGECOMPATONLY,0};
 enable(!is,raws);
 cbxSetCurSel(IDC_CBX_OUT_DV_PROFILE,cfgGet(IDFF_outDVnorm));
}
void ToutcspsPage::csp2dlg(void)
{
 int hwdeint=cfgGet(IDFF_hwOverlay)!=0 && cfgGet(IDFF_hwDeinterlace);
 setCheck(IDC_CHB_OUT_I420 ,cfgGet(IDFF_outI420  ));enable(!hwdeint,IDC_CHB_OUT_I420);
 setCheck(IDC_CHB_OUT_YV12 ,cfgGet(IDFF_outYV12  ));enable(!hwdeint,IDC_CHB_OUT_YV12);
 setCheck(IDC_CHB_OUT_YUY2 ,cfgGet(IDFF_outYUY2  ));
 setCheck(IDC_CHB_OUT_YVYU ,cfgGet(IDFF_outYVYU  ));
 setCheck(IDC_CHB_OUT_UYVY ,cfgGet(IDFF_outUYVY  ));
 setCheck(IDC_CHB_OUT_NV12 ,cfgGet(IDFF_outNV12  ));
 setCheck(IDC_CHB_OUT_RGB32,cfgGet(IDFF_outRGB32 ));
 setCheck(IDC_CHB_OUT_RGB24,cfgGet(IDFF_outRGB24 ));
 setCheck(IDC_CHB_OUT_RGB15,cfgGet(IDFF_outRGB555));
 setCheck(IDC_CHB_OUT_RGB16,cfgGet(IDFF_outRGB565));
 setCheck(IDC_CHB_OUT_CLOSESTMATCH,cfgGet(IDFF_outClosest));
 setCheck(IDC_CHB_AVISYNTH_YV12_RGB,cfgGet(IDFF_avisynthYV12_RGB));
}
void ToutcspsPage::overlay2dlg(void)
{
 int isHW=cfgGet(IDFF_hwOverlay);
 int enabledHW=(filterMode&IDFF_FILTERMODE_VFW)==0;
 int dv=cfgGet(IDFF_outDV);
 setCheck3(IDC_CHB_HWOVERLAY,isHW);
 enable(enabledHW && !dv,IDC_CHB_HWOVERLAY);
 int hwdeint=cfgGet(IDFF_hwDeinterlace);
 setCheck(IDC_CHB_HWDEINTERLACE,hwdeint);
 enable(!dv && isHW && enabledHW,IDC_CHB_HWDEINTERLACE);
 cbxSetCurSel(IDC_CBX_OUT_HWDEINT_METHOD,cfgGet(IDFF_hwDeintMethod));
 enable(!dv && isHW && enabledHW && hwdeint,IDC_CBX_OUT_HWDEINT_METHOD);
}
void ToutcspsPage::dfc2dlg(void)
{
 int is=(filterMode&IDFF_FILTERMODE_VFW)==0;
 int set=cfgGet(IDFF_allowOutChange);
 int dv=cfgGet(IDFF_outDV);
 setCheck3(IDC_CHB_ALLOWOUTCHANGE,set);enable(is && !dv,IDC_CHB_ALLOWOUTCHANGE);
 setCheck(IDC_CHB_OUTCHANGECOMPATONLY,cfgGet(IDFF_outChangeCompatOnly));enable(is && set==1 && !dv,IDC_CHB_OUTCHANGECOMPATONLY);
}

INT_PTR ToutcspsPage::msgProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
{
 switch (uMsg)
  {
   case WM_COMMAND:
    switch (LOWORD(wParam))
     {
      case IDC_CHB_HWOVERLAY:
       cfgSet(IDFF_hwOverlay,getCheck3(IDC_CHB_HWOVERLAY));
       overlay2dlg();
       csp2dlg();
       return TRUE;
      case IDC_CHB_HWDEINTERLACE:
       cfgSet(IDFF_hwDeinterlace,getCheck(IDC_CHB_HWDEINTERLACE));
       overlay2dlg();
       csp2dlg();
       return TRUE;
      case IDC_CHB_ALLOWOUTCHANGE:
       cfgSet(IDFF_allowOutChange,getCheck3(IDC_CHB_ALLOWOUTCHANGE));
       dfc2dlg();
       return TRUE;
      case IDC_CHB_OUT_DV:
       {
        int isdv=getCheck(IDC_CHB_OUT_DV);
        if(isdv)
         {
          if(!backupDV)
           backupDV=(int*)malloc(sizeof(int)*countof(idcs));
          if(!backupDV)
           return FALSE;
          for (int i=0;i<countof(idcs);i++)
           {
            backupDV[i]=getCheck3(idcs[i]);
            setCheck(idcs[i],0);
           }
         }
        else
         {
          if(backupDV)
           {
            for (int i=0;i<countof(idcs);i++)
             {
              setCheck3(idcs[i],backupDV[i]);
             }
           }
          else
           {
            deciD->resetFilter(filterID);
           }
         }
       }
      case IDC_CHB_OUT_I420:
      case IDC_CHB_OUT_YV12:
      case IDC_CHB_OUT_YUY2:
      case IDC_CHB_OUT_YVYU:
      case IDC_CHB_OUT_UYVY:
      case IDC_CHB_OUT_NV12:
      case IDC_CHB_OUT_RGB32:
      case IDC_CHB_OUT_RGB24:
      case IDC_CHB_OUT_RGB15:
      case IDC_CHB_OUT_RGB16:
       {
        int ch[countof(idcs)],dv=false;
        int is=0;
        for (int i=0;i<countof(idcs);i++)
         is|=ch[i]=getCheck(idcs[i]);
        if (getCheck(IDC_CHB_OUT_DV))
         if (!is)
          dv=true;
         else
          setCheck(IDC_CHB_OUT_DV,0);
        if (is || dv)
         {
          for (int i=0;i<countof(idcs);i++)
           cfgSet(idffs[i],ch[i]);
          cfgSet(IDFF_outDV,dv);
         }
        else
         setCheck(LOWORD(wParam),!getCheck(LOWORD(wParam)));
        csp2dlg();dv2dlg();overlay2dlg();dfc2dlg();
        return TRUE;
       }
     }
    break;
  }
 return TconfPageDecVideo::msgProc(uMsg,wParam,lParam);
}

void ToutcspsPage::getTip(char_t *tipS,size_t len)
{
 if (cfgGet(IDFF_flip)) strcpy(tipS,_l("Flip video"));
 else tipS[0]='\0';
}

void ToutcspsPage::translate(void)
{
 TconfPageDecVideo::translate();

 cbxTranslate(IDC_CBX_OUT_DV_PROFILE,ToutputVideoSettings::dvNorms);
 cbxTranslate(IDC_CBX_OUT_HWDEINT_METHOD,ToutputVideoSettings::deintMethods);
}

ToutcspsPage::ToutcspsPage(TffdshowPageDec *Iparent):TconfPageDecVideo(Iparent)
{
 backupDV=NULL;
 dialogId=IDD_OUTCSPS;
 //helpURL="in_out.html";
 inPreset=1;
 idffOrder=maxOrder+3;
 filterID=IDFF_filterOutputVideo;
 static const TbindCheckbox<ToutcspsPage> chb[]=
  {
   IDC_CHB_FLIP,IDFF_flip,NULL,
   IDC_CHB_OUTCHANGECOMPATONLY,IDFF_outChangeCompatOnly,NULL,
   IDC_CHB_HWDEINTERLACE,IDFF_hwDeinterlace,&ToutcspsPage::csp2dlg,
   IDC_CHB_AVISYNTH_YV12_RGB,IDFF_avisynthYV12_RGB,NULL,
   IDC_CHB_OUT_CLOSESTMATCH,IDFF_outClosest,NULL,
   0,NULL,NULL
  };
 bindCheckboxes(chb);
 static const TbindCombobox<ToutcspsPage> cbx[]=
  {
   IDC_CBX_OUT_HWDEINT_METHOD,IDFF_hwDeintMethod,BINDCBX_SEL,NULL,
   IDC_CBX_OUT_DV_PROFILE,IDFF_outDVnorm,BINDCBX_SEL,NULL,
   0
  };
 bindComboboxes(cbx);
}
