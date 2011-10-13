/*****************************************************************************
 *
 *  XVID MPEG-4 VIDEO CODEC
 *  - Font header (contains the font definition) -
 *
 *  Copyright(C) 2002-2003 Peter Ross <pross@xvid.org>
 *
 *  This program is free software ; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation ; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY ; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program ; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 * $Id: font.h 1988 2011-05-18 09:10:05Z Isibaar $
 *
 ****************************************************************************/

#ifndef _XVID_FONT_H_
#define _XVID_FONT_H_

#include "image.h"

void image_printf(IMAGE * img, int edged_width, int height, int x, int y, char *fmt, ...);

#endif /* _XVID_FONT_H_ */
