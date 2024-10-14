# Indigo4L
# SC1721

# 원본 파일명 : Flash Read_Write_231207.par 
# ksw 

# 0x60100000 : 엑셀에 영역 설정 안 되어 있음.

i4copy		0x60140030	0x617c7000	500			# Int.Flash.Sector7(Flash Read, 0x617c7000) -> SRAM(CODE Read, 0x60140030)
i4copy		0x60140300	0x617c8000	2100		# Int.Flash.Sector8(Flash Write, 0x617c8000) -> SRAM(CODE Write, 0x60140300) 

fncCall 		#name:Flash_Write#

fncCall 		#name:Flash_Read#

i4end

fncBegin		#name:Flash_Write#
w32		0x60140020	0x00000000		# Write C 
w32		0x60140004	0x00400000		# DST Address - Flash 저장 시작 주소/ Flash 이미지 저장 위치 
w32		0x60140008	0x0001E000		# Data Size, 120KB 
w32		0x6014000C	0x60100000		# SRC Address - Data 위치 / RAM 이미지 저장 위치#
i4jump		0x60140300				# SRAM(CODE Write) # Flash_Write_231106.par 호출??? 
fncEnd		    #name:Flash_Write#  # SRAM에서 Flash로 써라? 

fncBegin		#name:Flash_Read#
w32		0x60140010	0x00000000		# Read C 
w32		0x60140004	0x60100000		# DST Address - RAM 이미지 복사 영역 #
w32		0x60140008	0x0001E000		# Data Size, 120KB 
w32		0x6014000C	0x00400000		# SRC Address - Data 위치 / Flash 이미지 저장 위치 #
i4jump		0x60140300				# SRAM(CODE Write) # Flash_Read_231106.par 호출??? 
fncEnd		    #name:Flash_Read#   # Flash에서 SRAM으로 읽어라?? 

i4end
