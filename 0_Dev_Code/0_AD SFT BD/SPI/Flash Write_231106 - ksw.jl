# Indigo4L
# SC1721

# 원본 파일명 : Flash_Write_231106.par 
# ksw 
 

# Internal Flash - Erase&Write는 F/W update 기능에만 사용??? 
# 

# External Flash : IS25LP128 (ISSI, 128Mb == 16MB)
#                256 Bytes : Page 
#                 4 KB : Sector (0~4095)
#                


i4write	32	0x00026000	0x00000011		#path:INDIGO3X.HS_SPI.MCTRL
# MCTRL : HS_SPI Module Control Register
# [4] MES : Module enable status - read only라서 이 부분 수정해야 함. 
# [1] CSEN : Direct mode is enabled. Command sequencer is disabled
# [0] MEN : Module is enabled

# Data Size가 0인지 확인, 0이면 종료 
i4drget	32	0x60140008          # DREG1 = DREG0, DREG0 = *(0x60140008)  # Data Size 
i4jumprdr1notzero0	2			# IF DREG0 != 0, JUMP i4drget~          # IF Data Size != 0    
i4end				            # IF Data Size == 0, end 

# Data Size가 1 Sector (0x1000) 보다 작은지 확인. 
i4drget	32	0x60140008			# DREG1 = DREG0, DREG0 = *(0x60140008)  # Data Size 
i4drand		0x00000FFF			# DREG0 &= 0xFFF, 1Sector (1000) 보다 작은지 Check #
i4jumprdr1notzero0	6			# IF DREG0 != 0, JUMP, 1섹터보다 크면 점프 
# Data size is greater than 0x00001000

# Data Size가 1 Sector (0x1000) 보다 작다면, 
i4drget	32	0x60140008			# DREG1 = DREG0, DREG0 = *(0x60140008)  # Data Size 
i4drshiftr	12				    # DREG0 >>= 12 
i4drsave	2				    # Buffer[2] = DREG0     ## Flash Read & Write 
i4jumpr	7				        # 
# JUMP -> i4drload	0x61700000		# DREG1 = DREG0, DREG0 = 0x61700000 	

# Data Size가 1 Sector (0x1000) 보다 크다면, 
i4drget	32	0x60140008			# DREG1 = DREG0, DREG0 = *(0x60140008)  # Data Size
i4drshiftr	12				    # DREG0 >>= 12  # 
i4dradd		0x00000001          # DREG0++
i4drsave	2				    # Buffer[2] = DREG0 
i4drload	0x61700000		    # DREG1 = DREG0, DREG0 = 0x61700000
i4drget	32	0x60140004			# DREG1 = DREG0, DREG0 = *(0x60140004)  # DST Address 

# Write 영역이 Int. or Ext. Flash ??? 
jmpnamed	<	0x00000000	    #name:INTERNAL#     # IF DREG1 < DREG0, JUMP INTERNAL 	
# IF DREG1(0x61700000) < DREG0(DST Address), execute Internal_Flash_Write 
i4drsave	3				    # Buffer[3] = DREG0 

fncCall			#name:External_Flash_Write#		
i4end					

lblnamed		#name:INTERNAL#		
fncCall			#name:Internal_Flash_Write#		
i4end

############################################################################################################################					
##################################################### Internal Flash Write ######################################################					

######################### Sector Erase  ############################					
fncBegin			                #name:INTERNAL_SECTOR_ERASE#    # F/W 업데이트 때 사용 

i4flasherase	0	FALSE   # 0번 Sector, ksw - False로 해서 실제로는 안 지워짐. 이 부분 확인 필요
# F/W update 외에는 이 부분 쓸 일이 없음. 

    # 반복문 시작 - Internal Flash - Erase 완료 될 때까지 대기, 완료 되면 반복문 탈출. 
    lblnamed			    #name:CMD_Ready_Check1#		
    rf32		0x0002D010	0 1		# INDIGO4L.FLASH_CFG_CMDSEQ.STATUS_CTRL #   # 주소, 비트 시작, 비트 길이 
    # STATUS_CTRL : Flash Status Register 
    # [31] macro_rdy, R : Signals whether flash macro is ready
    #                   0: power_down - Flash is in power down mode
    #                   1: ready - Flash macro is ready
    # [1] cmd_err, R : Signals command error
    # [0] cmd_rdy, R : Signals whether flash macro is ready to accept new command

    i4drcheck		0x00000001		# IF [0] cmd_rdy == 0???  
        jmpnamed	always	0	    #name:CMD_Ready_Check1#         # IF DREG0 != 0x00000001, JUMP CMD_Ready_Check1    
    #반복문 끝 

fncEnd			                    #name:INTERNAL_SECTOR_ERASE#    # IF DREG0 == 0x00000001, RET 


######################### Sector Write  ############################					
fncBegin			    #name:INTERNAL_WRITE#		

d	1000			    # 1ms 	
i4flashprog	0x00000000	0x00000000	16383	FALSE   # 16383 == 1 sector 4KB, 4096 
# 16383 나누기 4 
# 재확인  
# 16383 == 0x3FFF, 16KB
# ksw - DST, SRC addr 모두 동일한 주소. 
# ksw - 이것도 Flash Read_231106.par 내의 i4copy 처럼 명령어가 특정 주소에 있어야 하는 건지???????? 

d	1000			    # 1ms 	

    # 반복문 시작  
    lblnamed			    #name:CMD_Ready_Check2#		
    rf32		0x0002D010	0 1		# INDIGO4L.FLASH_CFG_CMDSEQ.STATUS_CTRL #
    i4drcheck		0x00000001			# IF 
        jmpnamed	always	0	        #name:CMD_Ready_Check2#     # IF DREG0 != 0x00000001, JUMP CMD_Ready_Check2
    # 반복문 끝     

fncEnd			        #name:INTERNAL_WRITE#		# IF DREG0 == 0x00000001, RET 


############################################################################################################################					
################################################### External Flash Write #######################################################					

fncBegin			#name:External_Flash_Write#		

# 반복문 시작 
lblnamed			#name:Sector_Erase#		


fncCall			    #name:Write_Start_COMPLETE#

i4drput	32	0x60140014			        # Read Ready = DREG0  					
i4write	32	0x00026038	0x00000000		#path:INDIGO4.HS_SPI.DMSTART
i4write	32	0x0002604C	0x00001841		#path:INDIGO4.HS_SPI.FIFOCFG
i4write	32	0x0002603C	0x00000004		#path:INDIGO4.HS_SPI.DMBCC
i4write	32	0x00026050	0x00000020		#path:INDIGO4.HS_SPI.TXFIFO0 

i4drrestore	3				            # DREG1 = DREG0, DREG0 = Buffer[3] 
i4drand		0x00FF0000			        # DREG0 &= 0x00FF0000
i4drshiftr	16				            # DREG0 >>= 16 
i4drput	32	0x00026050			        # 0x00026050 = DREG0 
i4drrestore	3				            # DREG1 = DREG0, DREG0 = Buffer[3] 
i4drand		0x0000F000			        # DREG0 &= 0x0000F000
i4drshiftr	8				            # DREG0 >>= 8 
i4drput	32	0x00026050			        # TXFIFO0 = DREG0 
i4write	32	0x00026050	0x00000000		#path:INDIGO4.HS_SPI.TXFIFO0
i4write	32	0x00026038	0x00000001		#path:INDIGO4.HS_SPI.DMSTART

    # 반복문 시작 
    lblnamed			                    #name:Read_Check_1#		
    i4wait	250				                # 250us 

    fncCall			#name:READY_Check#		

    i4drcheck	0x00000000			        # IF 
        jmpnamed	always	0	#name:Read_Check_1#		# IF DREG0 != 0, JUMP 
    # 반복문 끝 
        i4drput	32	0x60140014			                # IF DREG0 == 0, Read Ready = DREG0 

i4drrestore	3				            # DREG1 = DREG0, DREG0 = Buffer[3] 
i4dradd		0x00001000			        # DREG0 += 0x1000 
i4drsave	3				            # Buffer[3] = DREG0 
i4drrestore	2				            # DREG1 = DREG0, DREG0 = Buffer[2] 
i4dradd		0xFFFFFFFF			        # DREG0 += 0xFFFFFFFF
i4drsave	2				            # Buffer[2] = DREG0 

jmpnamed	notzero	0	                #name:Sector_Erase#     # IF DREG0 != 0, JUMP 
# 반복문 끝 				

######################### Sector Write  ############################					
i4drget	32	0x60140004			
i4drsave	1				            # Buffer[1] = DREG0 
d	1000				                # 1ms 
i4write	32	0x60140020	0x11111111		# Write C = 0x11111111
i4write	32	0x60140018	0x00000000		# LoopCount=0
i4drget	32	0x60140008			        # DREG1 = DREG0, DREG0 = *(0x60140008), Data Size 
i4drshiftr	8				            # DREG0 >>= 8 
i4drput	32	0x6014002C			        # Data Size CV = DREG0 

# 반복문 start 
lblnamed			                    #name:Sector_Write#		


fncCall			                        #name:Write_Start_COMPLETE#		

i4drput	32	0x60140028			        # Write Ready = DREG0 
i4write	32	0x00026038	0x00000000		#path:INDIGO4.HS_SPI.DMSTART
i4write	32	0x0002604C	0x00001841		#path:INDIGO4.HS_SPI.FIFOCFG
i4write	32	0x0002603C	0x00000104		#path:INDIGO4.HS_SPI.DMBCC
i4write	32	0x00026050	0x00000002		#path:INDIGO4.HS_SPI.TXFIFO0
i4drrestore	1				            # DREG1 = DREG0, DREG0 = Buffer[1] 
i4drand		0x00FF0000			        # DREG0 &= 0x00FF0000 
i4drshiftr	16				            # DREG0 >>= 16
i4drput	32	0x00026050			        #path:INDIGO4.HS_SPI.TXFIFO0 
i4drrestore	1				            # DREG1 = DREG0, DREG0 = Buffer[1] 
i4drand		0x0000FF00			        # DREG0 &= 0x0000FF00
i4drshiftr	8				            # DREG0 >>= 8 
#path:INDIGO4.HS_SPI.TXFIFO0
i4drput	32	0x00026050			        # TXFIFO0 = DREG0 
i4write	32	0x00026050	0x00000000		# TXFIFO0 = 0x00 
					
i4drrestore	1				            # DREG1 = DREG0, DREG0 = Buffer[1] 
i4drput	32	0x60140024			        # DST C W = DREG0 
					
    # 반복문 Start 
    lblnamed			                    #name:256byte_Write#		
    i4drget	32	0x60140018			        # DREG1 = DREG0, DREG0 = *(0x60140018), Loop Count W 
    i4drcheck	0x00000040			        # IF 
        i4jumpr	2				                                # IF DREG0 != 0x40, 
        jmpnamed	always	0	#name:256byte_Write_END#        # IF DREG0 == 0x40, 

    i4drshiftl	2				            # DREG0 <<= 2 
    i4drget	32	0x6014000C			        # DREG1 = DREG0, DREG0 = *(0x6014000C), SRC Address 
    i4dr1add0					            # DREG0 += DREG1 
    i4drput	32	0x6014001C			        # 0x6014001C = DREG0, C SRC Address 

    i4arget		0x6014001C			        # AREG = *(0x6014001C), C SRC Address 
    i4argetindirect	32				        # DREG1 = DREG0, DREG0 = *(AREG)

    i4drsave	0				            # Buffer[0] = DREG0 
    i4drand		0x000000FF			        # DREG0 &= 0xFF 
    i4drput	32	0x00026050                  #path:INDIGO4.HS_SPI.TXFIFO0
    i4drrestore	0				            # DREG1 = DREG0, DREG0 = Buffer[0]
    i4drand		0x0000FF00			        # DREG0 &= 0xFF00 
    i4drshiftr	8				            # DREG0 >>= 8 
    i4drput	32	0x00026050			        #path:INDIGO4.HS_SPI.TXFIFO0
    i4drrestore	0				            # DREG1 = DREG0, DREG0 = Buffer[0]
    i4drand		0x00FF0000			        # DREG0 &= 0x00FF0000 
    i4drshiftr	16				            # DREG0 >>= 16  
    i4drput	32	0x00026050			        #path:INDIGO4.HS_SPI.TXFIFO0
    i4drrestore	0				            # DREG1 = DREG0, DREG0 = Buffer[0]
    i4drand		0xFF000000			        # DREG0 &= 0xFF000000     
    i4drshiftr	24				            # DREG0 >>= 24  
    i4drput	32	0x00026050			        #path:INDIGO4.HS_SPI.TXFIFO0
    i4write	32	0x0002604C	0x00001841		#path:INDIGO4.HS_SPI.FIFOCFG
    i4drget	32	0x60140018			        # DREG1 = DREG0, DREG0 = *(0x60140018), Loop Count W 
    i4dradd		0x00000001			        # DREG0++ 
    i4drput	32	0x60140018			        # Loop Count W = DREG0 
    jmpnamed	always	0	                #name:256byte_Write#		
    # 반복문 End 
					
# 
lblnamed			#name:256byte_Write_END#		
i4write	32	0x00026038	0x00000001		#path:INDIGO4.HS_SPI.DMSTART
i4write	32	0x00026039	0x00000001		#path:INDIGO4.HS_SPI.DMSTOP
i4write	32	0x60140018	0x00000000		# Loop Count W 
i4drget	32	0x6014001C			        # DREG1 = DREG0, DREG0 = *(0x6014001C), C SRS Address 
i4dradd		0x00000004			        # DREG0 += 0x04 
i4drput	32	0x6014000C			        # SrcAddress = CurrentSrcAddress
i4drrestore	1				            # DREG1 = DREG0, DREG0 = Buffer[1]
i4dradd		0x00000100			        # DREG0 += 0x100
i4drsave	1				            # Buffer[1] = DREG0
i4drget	32	0x6014002C			        # DREG1 = DREG0, DREG0 = *(0x6014002C), Data Size CV 
i4dradd		0xFFFFFFFF			        # DREG0 += 0xFFFFFFFF
i4drput	32	0x6014002C                  # Data Size CV = DREG0 

jmpnamed	notzero	0	#name:Sector_Write#     # IF DREG0 != 0, JUMP 
# 반복문 End 

i4write	32	0x60140020	0x33333333		# Write C = 
					
fncCall			                        #name:Write_End_COMPLETE#		
					
i4write	32	0x60140020	0x55555555      # Write C, Success_flag == 0x55555555		
fncEnd			                        #name:External_Flash_Write#		


############################################################################################################################					
################################################### Internal Flash Write #######################################################					

fncBegin			#name:Internal_Flash_Write#		

lblnamed			        #name:INTERNAL_ERASE_WRITE#		

# Data Size가 192KB 넘는지 확인 
i4drload	0x00030000      # DREG1 = DREG0, DREG0 = 0x00030000
i4drget	32	0x60140008		# DREG1 = DREG0, DREG0 = *(0x60140008), Data Size 
jmpnamed	<	0x00000000	#name:OUT_OF_MEMORY#    # IF DREG1 < DREG0, JUMP OUT_OF_MEMORY 		

# Data Size가 192KB보다 작다면, 시작 
i4drshiftr	12				# DREG0 >>= 12 
i4jumprdr1notzero0	3		# IF DREG0 != 0, JUMP
    i4dradd		0x00000001		# DREG0++ 	
    i4drsave	1				# Buffer[1] = DREG0 
i4drget	32	0x60140004		# DREG1 = DREG0, DREG0 = *(0x60140004), DST Address 
i4drand		0x0003F000		# DREG0 &= 0x0003F000	
i4drshiftr	12				# DREG0 >>= 12 
i4drsave	0				# Buffer[0] = DREG0 
			
# 반복문 시작 
lblnamed			        #name:Sector_Erase_LOOP#		
    i4drrestore	0				# DREG1 = DREG0, DREG0 = Buffer[0]
    i4drput	16	0x60140386		# 0x60140386 = DREG0, Sector E 

    fncCall			#name:INTERNAL_SECTOR_ERASE#		

    i4drrestore	0				# DREG1 = DREG0, DREG0 = Buffer[0]
    i4dradd		0x00000001		# DREG0++ 	
    i4drsave	0				# Buffer[0] = DREG0 
    i4drrestore	1				# DREG1 = DREG0, DREG0 = Buffer[1] 
    i4dradd		0xFFFFFFFF		# DREG0 += 0xFFFFFFFF	
    i4drsave	1				# Buffer[1] = DREG0 
jmpnamed	notzero	0	    #name:Sector_Erase_LOOP#    # IF DREG1 != 0, JUMP Sector_Erase_Loop 		
# 반복문 끝 
					
i4drget	32	0x60140004		#	
i4drsave	0				# Buffer[0] = DREG0 
i4drget	32	0x6014000C		#	
i4drsave	2				# Buffer[2] = DREG0 
i4drget	32	0x60130008		# SECTOR 단위로 반복 횟수 지정#
i4drshiftr	12				# DREG0>>=12 
i4drsave	1				# Buffer[1] = DREG0 

jmpnamed	notzero	0	    #name:LOOP_D#       # IF DREG1 != 0, JUMP LOOP_D 

i4drget	32	0x60140008      # DREG1 = DREG0, DREG0 = *(0x60140008), Data Size 
i4drshiftr	3				# DREG0 >>= 3 
i4drput	16	0x601403BE		# Data Size W = (16)DREG0 
i4drget	32	0x60140004		# DREG1 = DREG0, DREG0 = *(0x60140004), DST Address 
i4drput	32	0x601403C0		# DST Address W = DREG0 	
i4drget	32	0x6014000C		# DREG1 = DREG0, DREG0 = *(0x6014000C), SRC Address 	
i4drput	32	0x601403C4		# SRC Address W = DREG0 	

fncCall			#name:INTERNAL_WRITE#		

i4write	32	0x60140020	0x55555555      # Write C, Success_flag == 0x55555555

jmpnamed	always	0	#name:END#		
					
    # 반복문 시작 
    lblnamed			#name:LOOP_D#		
    i4write	16	0x601403BE	0x00000200      # size addr, data - 0200만 wrtie 
    # ksw - 만약 data가 0xFF00FF00인데 16 size로 할 경우? 	0x0000FF00 

    i4drrestore	0               # DREG1 = DREG0, DREG0 = Buffer[0] 
    i4drput	32	0x601403C0      # DST Address W = DREG0 
    i4dradd		0x00001000		# DREG0 += 0x00001000	
    i4drsave	0				# Buffer[0] = DREG0 
    i4drrestore	2				# DREG1 = DREG0, DREG0 = Buffer[2] 
    i4drput	32	0x601403C4		# 0x601403C4 = DREG0, SRC Address W 
    i4dradd		0x00001000		# DREG0 += 0x00001000	
    i4drsave	2				# Buffer[2] = DREG0 

    fncCall			#name:INTERNAL_WRITE#		

    i4drrestore	1				# DREG1 = DREG0, DREG0 = Buffer[1] 
    i4dradd		0xFFFFFFFF		# DREG0 += 0xFFFFFFFF	
    i4drsave	1				# Buffer[1] = DREG0 

    jmpnamed	notzero	0	#name:LOOP_D#       # IF DREG0 != 0, JUMP LOOP_D 		
    # 반복문 끝 

i4drget	32	0x60140008		# DREG1 = DREG0, DREG0 = Data Size 
i4drand		0x00000FFF      # DREG0 &= 0xFFF 
i4drshiftr	3				# DREG0 >>= 3
i4drput	16	0x601403BE		# Data Size W = (16)DREG0 	
i4drrestore	0				# DREG1 = DREG0, DREG0 = Buffer[0]
i4drput	32	0x601403C0		# DST Address W = DREG0 	
i4drrestore	2				# DREG1 = DREG0, DREG0 = Buffer[2] 
i4drput	32	0x601403C4		# SRC Address W = DREG0 

fncCall			#name:INTERNAL_WRITE#		

i4write	32	0x60140020	0x55555555      # Write C, Success_flag == 0x55555555

jmpnamed	always	0	#name:END#		

lblnamed			    #name:OUT_OF_MEMORY#		
i4write	32	0x60140020	0x22222222      # Write C, Fail_flag == 0x22222222 		

lblnamed		    	#name:END#
fncEnd			        #name:Internal_Flash_Write#		


############################################################################################################################					
##################################################### External Flash Write ######################################################					

######################### Sector Write Start  ############################					
# External Flash - Write 가능 여부 확인 
fncBegin			#name:Write_Start_COMPLETE#		
    # 반복문 시작 
    lblnamed			#name:Write_Start#		

    fncCall			    #name:Write_Enable#		

    i4wait	250			# 250us 	

    fncCall			    #name:READY_Check#		

    i4drcheck	0x00000002      # IF 			
        jmpnamed	always	0	#name:Write_Start#          # IF DREG0 != 0x02, JUMP 
    # 반복문 끝 
fncEnd			    #name:Write_Start_COMPLETE#     # IF DREG0 == 0x02, RET 		

######################### Sector Write END ############################					
fncBegin			    #name:Write_End_COMPLETE#	
	
    # 반복문 시작 
    lblnamed			#name:Write_END#		
    i4wait	250			# 250us 	

    fncCall			    #name:Write_Disable#		

    i4wait	250			# 250us 	

    fncCall			    #name:READY_Check#		

    # 중첩 조건문 
    i4drcheck		0x00000002		# IF DREG0 == 0x02, 			
        i4jumprdr1zero0	2		    #name:Write_END#            # IF DREG0 == 0, JUMP Write_END     		
    # 반복문 끝 

fncEnd			        #name:Write_End_COMPLETE#   # IF DREG0 == 0x02, RET 		


######################### Write Disable  ############################					
# WRITE DISABLE OPERATION (WRDI, 04h)
fncBegin			#name:Write_Disable#		
i4write	32	0x00026038	0x00000000		#path:INDIGO4.HS_SPI.DMSTART
# DMSTART : HS_SPI Direct Mode Start Register 
# [0] START : Start Transfer, 0 No effect, 
i4write	32	0x0002604C	0x00001811		#path:INDIGO4.HS_SPI.FIFOCFG
# FIFOCFG : HS_SPI FIFO Configuration Register 
# [12] TXFLSH : TX-FIFO Flush - 1: Flushes the TX-FIFO 
# [11] RXFLSH : 
# [7:4] TXFTH : TX-FIFO Threshold level 
# [3:0] RXFTH : RX-FIFO Threshold level 

i4write	32	0x0002603C	0x00000001		#path:INDIGO4.HS_SPI.DMBCC
i4write	32	0x00026050	0x00000004		#path:INDIGO4.HS_SPI.TXFIFO0
i4write	32	0x00026038	0x00000001		#path:INDIGO4.HS_SPI.DMSTART
i4write	32	0x00026039	0x00000001		#path:INDIGO4.HS_SPI.DMSTOP
fncEnd			#name:Write_Disable#		

######################### Write Enable  ############################			
# WRITE ENABLE OPERATION (WREN, 06h)
fncBegin			#name:Write_Enable#		
i4write	32	0x00026038	0x00000000		#path:INDIGO4.HS_SPI.DMSTART
i4write	32	0x0002604C	0x00001811		#path:INDIGO4.HS_SPI.FIFOCFG
i4write	32	0x0002603C	0x00000001		#path:INDIGO4.HS_SPI.DMBCC
i4write	32	0x00026050	0x00000006		#path:INDIGO4.HS_SPI.TXFIFO0
i4write	32	0x00026038	0x00000001		#path:INDIGO4.HS_SPI.DMSTART
i4write	32	0x00026039	0x00000001		#path:INDIGO4.HS_SPI.DMSTOP
fncEnd			#name:Write_Enable#		

######################### Ready Check  ############################				
# External Flash - 접근 가능한 상태인지 Ext. Flash Register 확인 
# READ STATUS REGISTER OPERATION (RDSR, 05h)
fncBegin			#name:READY_Check#		
i4write	32	0x00026038	0x00000000		#path:INDIGO4.HS_SPI.DMSTART
i4write	32	0x0002604C	0x00001821		#path:INDIGO4.HS_SPI.FIFOCFG
i4write	32	0x0002603C	0x00000002		#path:INDIGO4.HS_SPI.DMBCC
i4write	32	0x00026050	0x00000005		#path:INDIGO4.HS_SPI.TXFIFO0
i4write	32	0x00026050	0x00000000		#path:INDIGO4.HS_SPI.TXFIFO0
# ksw - TXFIFO0 2번 쓰는 이유가??? 
i4write	32	0x00026038	0x00000001		#path:INDIGO4.HS_SPI.DMSTART
i4write	32	0x00026039	0x00000001		#path:INDIGO4.HS_SPI.DMSTOP
i4drget	32	0x00026090			        # DREG1 = DREG0, DREG0 = *(RXFIFO0)
i4drget	32	0x00026090			        # DREG1 = DREG0, DREG0 = *(RXFIFO0)
# 0x00026090 == RXFIFO0 
# ksw - RXFIFO0 두번 get 하는 이유가???? 
fncEnd			#name:READY_Check#		

############################################################################################################################					
					
i4end					
e
