# Indigo4L
# SC1721

# 원본 파일명 : Flash Read_231106.par 
# ksw 
# Internal Flash : Sector 7, 0x617C 7000 ~ 0x617C 7FFF 
# SRAM : 0x6014 0030 
# Global Setting 부분 : i4copy		0x60140030	0x617c7000	500(0x1F4)

# 0x60140008 : Data Size 
# 0x60140010 : Read C 
# 0x601401BA : Data Size R 
# 0x60140004 : Destination Address 
# 0x601401BC : Destination Address R 
# 0x6014000C : Source Address 


w32		0x00026000	0x00000013		# SPI Mode Change Direct Mode -> Command Sequencer Mode #
# HS_SPI.MCTRL : 
# [4] MES : Module enable status 
# [1] CSEN : CMDSEQ Enabled 
# [0] MEN : Module Enabled 
# ksw - 4번 비트는 Read only인데 write????? 

lblnamed			#name:MAIN_FUNC# # 

i4drget	32	0x60140008		# DREG1 = DREG0, DREG0 = *(0x60140008)	# 	Data Size 	
i4drload	0x00030000		# DREG1 = DREG0, DREG0 = 0x00030000
jmpnamed	>	0x00000000	#name:OUT_OF_MEMORY#	IF DREG1 > DREG0, JUMP OUT_OF_MEMORY 
                            # Data Size > 0x30000 == out of memory, 종료? 너무 큰 사이즈라서 종료인가???? 


i4drget	32	0x60140008		# DREG1 = DREG0, DREG0 = *(0x60140008)	# 	Data Size 	
i4drload	0x00000FFF		# DREG1 = DREG0, DREG0 = 0x00000FFF
jmpnamed	>	0x00000000	#name:CHECK_COUNT#		IF DREG1 > DREG0, JUMP CHECK_COUNT 


### Data Size <= 0xFFF, start # 읽어야 할 크기가 0xFFF보다 작거나 같으면,(1섹터 이내) 여기 시작 
i4drget	16	0x60140008		# DREG1 = DREG0, DREG0 = *(0x60140008)  # Data Size 
i4drput	16	0x601401BA		# 0x601401BA = DREG0 	                # Data Size R, Data Size R == Data Size  
i4drget	32	0x60140004		# DREG1 = DREG0, DREG0 = *(0x60140004)	# DST Address 
i4drput	32	0x601401BC		# 0x601401BC = DREG0 	                # DST Address R, DST Address R = DST Address 
i4drload	0x61700000		# DREG1 = DREG0, DREG0 = 0x61700000     # 
i4drget	32	0x6014000C		# DREG1 = DREG0, DREG0 = *(0x6014000C)	# SRC Address
# DREG1 == 0x61700000, DREG0 == SRC Address 
i4jumprdr1less0	3			# IF DREG1 < DREG0, JUMP 
    i4dradd		0x70000000		# DREG0 += 0x70000000
                                # IF 0x6170 0000 >= SRC Address, SRC Address R += 0x7000 0000 
    i4drput	32	0x601401C0		# 0x601401C0 = DREG0    # SRC Address R
                                # IF 0x6170 0000 < SRC Address, SRC Address R = SRC Address 

fncCall		#name:COPY_FUNC#

i4write	32	0x60140010	0x55555555	# OK END???? 	# Read C 
i4end
### 


### Data Size > 0xFFF, start # 읽어야할 크기가 0xFFF보다 크면,(1섹터보다 크면) 여기 시작 
lblnamed			#name:CHECK_COUNT#		
i4drget	32	0x60140008		# DREG1 = DREG0, DREG0 = *(0x60140008)	# Data Size 	
i4drand		0x0003F000		# DREG0 &= 0x0003F000	
i4drshiftr	12				# DREG0 >>= 12 
i4drsave	0				# Buffer[0] = DREG0 
i4drget	32	0x60140004		# DREG1 = DREG0, DREG0 = *(0x60140004)	# Dst Address 
i4drsave	1				# Buffer[1] = DREG0 
i4drload	0x61700000		# DREG1 = DREG0, DREG0 = 0x61700000	
i4drget	32	0x6014000C		# DREG1 = DREG0, DREG0 = *(0x6014000C)  # SRC Address 
i4jumprdr1less0	3			# IF  
    i4dradd		0x70000000		# DREG0 += 0x70000000	
    i4drsave	2				# Buffer[2] = DREG0

    # 반복문 시작 
    lblnamed			#name:COPY_LOOP#		
    i4write	16	0x601401BA	0x00001000		
    i4drrestore	1				# DREG1 = DREG0, DREG0 = Buffer[1] 
    i4drput	32	0x601401BC		# 0x601401BC = DREG0 	
    i4drrestore	2				# DREG1 = DREG0, DREG0 = Buffer[2] 
    i4drput	32	0x601401C0		# 0x601401C0 = DREG0 	
    
    fncCall		#name:COPY_FUNC#			

    i4drrestore	1				# DREG1 = DREG0, DREG0 = Buffer[1]	
    i4dradd		0x00001000		# DREG0 += 0x00001000			
    i4drsave	1				# Buffer[1] = DREG0 
    i4drrestore	2				# DREG1 = DREG0, DREG0 = Buffer[2] 
    i4dradd		0x00001000		# DREG0 += 0x00001000						
    i4drsave	2				# Buffer[2] = DREG0 
    i4drrestore	0				# DREG1 = DREG0, DREG0 = Buffer[0]
    i4dradd		0xFFFFFFFF		# DREG0 += 0xFFFFFFFF	

    i4drsave	0				# Buffer[0] = DREG0 
    jmpnamed	notzero	0	#name:COPY_LOOP#		# IF DREG0 != 0, JUMP COPY_LOOP
    # 반복문 끝 

i4drget	32	0x60140008		# DERG1 = DREG0, DREG0 = *(0x60140008)  # Data Size 
i4drand		0x000007FF		# DREG0 &= 0x000007FF

jmpnamed	zero 	0	    #name:OK_END#   # IF DREG0 == 0, JUMP 
                            # 읽어야 할 Data Size가 0. 즉 Read 동작 더 이상 불필요하므로 종료. 
                            # 읽어야 할 Data Size가 섹터 단위로 깔끔하게 떨어지면 여기서 끝. 

# 읽어야 할 Data Size가 Sector 단위로 끊어지지 않을 경우, 여기서 start 
i4drput	16	0x601401BA		# 0x601401BA = DREG0    # Data Size R 
i4drrestore	1				# DREG0 = Buffer[1]     
i4drput	32	0x601401BC		# 0x601401BC = DREG0 	# DST Address R 	
i4drrestore	2				# DREG0 = Buffer[2] 	
i4drput	32	0x601401C0		# 0x601401C0 = DREG0 	# SRC Address R 	

fncCall		#name:COPY_FUNC#

jmpnamed	always	0	#name:OK_END#

lblnamed			#name:OUT_OF_MEMORY#		
i4write	32	0x60140010	0x11111111		# Read C # ksw - 0x11111111이면 error flag? 
i4end

lblnamed			#name:OK_END#		
i4write	32	0x60140010	0x55555555		# Read C # ksw - 0x55555555이면 pass flag? 
i4end

##############################################################################################
fncBegin			#name:COPY_FUNC#
i4copy		0x60000000	0x70000000	0	
# Internal Flash에서는 i4copy 0x60000000 0x70000000 0 
# SRAM에서는 i4copy 0x601F7000 0x704A7000 0x1000 

# 0x60000000 == 0x601F7000 
# 0x70000000 == 0x704A7000 
fncEnd				#name:COPY_FUNC#
##############################################################################################

i4end
e
