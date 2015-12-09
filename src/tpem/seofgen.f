C     PROGRAM SEOFGEN GENERATES SHIFTED EOF'S 
c	USE PORTLIB
c      USE MSIMSL
      SUBROUTINE seofgen(CAP_COEF,NP_cap,
     1                   HEIGHT_ARRAY,M_PROFILE,Npt,i_valid,base_par)	
      PARAMETER(N_HT_S=100,N_HT_B=100,N_HT_U=200,N_PRF_S=100)	   
c     INPUT Parameters
      integer  NP_cap,npt    
      real  CAP_COEF(np_cap)
      real  base_par(4)
C     ARRAYS FOR DATA INPUT
	REAL EOF_S( N_HT_S , N_HT_S+1 )
	REAL EOF_B( N_HT_B )
	REAL EOF_U( N_HT_U )
	REAL EOF_S_SD( N_HT_S )
	COMMON / EOF_ARRS / EOF_S , EOF_B , EOF_U , EOF_S_SD	 

C     OUTPUT ARRAYS
	REAL M_PROFILE(500)
	REAL HEIGHT_ARRAY(500)

C     REFRACTIVITY PARAMETER VARIABLES
	REAL BASE_HT,mdeff,dz
	REAL MIXED_LAYER_SLOPE_DEV
	INTEGER NP 
	REAL CAP_INV_COEF(100)
	REAL FREE_TROPO_SLOPE_DEV
	COMMON / INPUT_PARAMS / BASE_HT , MIXED_LAYER_SLOPE_DEV,
     *         NP, CAP_INV_COEF, FREE_TROPO_SLOPE_DEV
C     WORKING VARIABLES    
      REAL HEIGHT_INC
      REAL RQD_MDEFF
      integer ifirst
      common /stored/ifirst

c the path to the seof directory
      integer nc ! number of caracters in string
      data nc/40/
      character*80     seof_dir
      data  seof_dir/'/net/clio/clio2/gerstoft/ted/vocar/seof/'/
        common /seofdir/seof_dir,nc

c	write(*,*)'seofdir2:', seof_dir(1:nc)//'TEST'


C     SET THE HEIGHT INCREMENT FIRST

      HEIGHT_INC = 3.		
      if (ifirst.eq.0) then	  
	CALL LOAD_EOF_S( N_HT_S , EOF_S )
	CALL LOAD_EOF_B( N_HT_B , EOF_B )
	CALL LOAD_EOF_U( N_HT_U , EOF_U )
	CALL LOAD_EOF_S_SD(  N_HT_S , EOF_S_SD )
        ifirst=1
       endif
c	CALL LOAD_PARAMETERS

c	OPEN(UNIT=7,FILE='/net/clio//clio2/gerstoft/ted/vocar/seof/mdeff.req',ACTION='READ')
c	READ(7,*) RQD_MDEFF	, BASE_HT
c	CLOSE(7)
c        req_mdeff= 10  
c        base_ht=400     
	

C     REFRACTIVITY PARAMETER VARIABLES
	
	 MIXED_LAYER_SLOPE_DEV=0
         NP =  NP_cap
         base_ht=CAP_COEF(1)
         do i=1,np
            CAP_INV_COEF(i)= CAP_COEF(i+1)
         enddo
         Npt=500
cpg         write(*,*)'from seofgen: ', base_ht,(CAP_COEF(i+1),i=1,np)
	 FREE_TROPO_SLOPE_DEV=0
cpg	   I_GEN_NUISANCE = 0
cpg	   CALL GEN_COEFFICIENTS( I_GEN_NUISANCE, EOF_S_SD,RQD_MDEFF )
	   CALL GEN_M_PROFILE(HEIGHT_ARRAY, M_PROFILE)
           CALL CALC_M_DEFICIT( M_PROFILE, MDEFF,dz ,I_VALID)
	 
cpg           call WRITE_M_FILE( HEIGHT_ARRAY, M_PROFILE )

c      CALL MDF2PRF( RQD_MDEFF , M_PROFILE , HEIGHT_ARRAY)
cpg	CALL WRITE_M_FILE( HEIGHT_ARRAY, M_PROFILE )
	
c  base_par profile
        base_par(1) = base_ht
        base_par(2) = mdeff
        base_par(3) = dz
        base_par(4) = m_profile(1)

	END
	


	SUBROUTINE MDF2PRF( RQD_MDEFF , M_PROFILE , HEIGHT_ARRAY )                               
	REAL RQD_MDEFF
	REAL M_PROFILE(500)
	REAL HEIGHT_ARRAY(500)


	PARAMETER(N_HT_S=100,N_HT_B=100,N_HT_U=200,N_PRF_S=100)	 
C     ARRAYS FOR DATA INPUT
	REAL EOF_S( N_HT_S , N_HT_S+1 )
	REAL EOF_B( N_HT_B )
	REAL EOF_U( N_HT_U )
	REAL EOF_S_SD( N_HT_S )
	COMMON / EOF_ARRS / EOF_S , EOF_B , EOF_U , EOF_S_SD	 
       
C     REFRACTIVITY PARAMETER VARIABLES
	
      REAL BASE_HT
	REAL MIXED_LAYER_SLOPE_DEV
	INTEGER NP 
	REAL CAP_INV_COEF(100)
	REAL FREE_TROPO_SLOPE_DEV
	COMMON / INPUT_PARAMS / BASE_HT , MIXED_LAYER_SLOPE_DEV,
     *         NP, CAP_INV_COEF, FREE_TROPO_SLOPE_DEV
	 
	REAL SAMP(500,20),MDEFF
	INTEGER I_VALID

		 
	INTEGER ILT, I_GEN_NUISANCE
	ILT = 0
	DO 348, II=1,1000000 
	   NP =	0
	   I_GEN_NUISANCE = 1
	   CALL GEN_COEFFICIENTS( I_GEN_NUISANCE, EOF_S_SD,RQD_MDEFF )
	   CALL GEN_M_PROFILE(HEIGHT_ARRAY, M_PROFILE)
         CALL CALC_M_DEFICIT( M_PROFILE, MDEFF,dz ,I_VALID)
	   IF (  (   MDEFF .LT. ( RQD_MDEFF +.5 ) ) .AND. 
     *	     (   MDEFF .GT. ( RQD_MDEFF -.5 ) ) .AND.
     *         (I_VALID .EQ. 1) )THEN
	      ILT=ILT+1
	      DO 355 IK = 1,500
	         SAMP(IK,ILT) = M_PROFILE(IK)
  355       CONTINUE
            IF (ILT .GT. 19) THEN
	         GOTO 349
	      END IF
	   END IF					 
  348 CONTINUE
  349 CONTINUE
C	OPEN(UNIT=10,FILE='SAMP.DAT',ACTION='WRITE')
C	DO 374, IHT = 1,500
C	   WRITE(10,375) (SAMP(IHT,I), I=1,20)
C  374 CONTINUE
C  375 FORMAT(20F7.1)
C      CLOSE(10)
	END



C     'CALC_M_DEFICIT'  SIMPLY CALCULATES THE M-DEFICIT FROM
C      THE ARRAY 'M_PROFILE' AND RETURNS 'MDEFF' AND 'DZ' WHICH
C      IS THE THICKNESS OF THE INVERSION, IT ALSO CHECKS
C      FOR A REVERSE M-DEFICIT, I.E. A KINK TO THE RIGHT AFTER

       SUBROUTINE CALC_M_DEFICIT( M_PROFILE, MDEFF, DZ, I_VALID )
       REAL    M_PROFILE(500),MDEFF
       INTEGER I_VALID
C     REFRACTIVITY PARAMETER VARIABLES
      REAL BASE_HT
      REAL MIXED_LAYER_SLOPE_DEV
	INTEGER NP 
	REAL CAP_INV_COEF(100)

	REAL FREE_TROPO_SLOPE_DEV
	COMMON / INPUT_PARAMS / BASE_HT ,MIXED_LAYER_SLOPE_DEV,
     *         NP, CAP_INV_COEF,FREE_TROPO_SLOPE_DEV


C     WORKING VARIABLES
      REAL MAXM
      REAL MINM

      INTEGER I_BASE_HT,I,I_HT

C     FIRST WE FIND THE HEIGHT INDEX CORRESPONDING TO THE BASE OF
C     THE CAPPING INVERSION
      I_BASE_HT = INT(BASE_HT / 3.+.5)+1
      MAXM   = M_PROFILE( I_BASE_HT )
      I_MAXM = I_BASE_HT
	

C     WE GO WITHIN 5 POINTS UP OR DOWN OF I_BASE_HT TO LOCATE THE 
C     A BETTER BASE HEIGHT (I.E. ONE WHICH IS FARTHER TO THE RIGHT)
	DO 273 I=1,10
	   I_HT = I_BASE_HT + I - 5
	   IF  (M_PROFILE( I_HT ) .GT. MAXM ) THEN
	       MAXM = M_PROFILE( I_HT )
	       I_MAXM = I_HT
	   END IF	  
 273    CONTINUE

C     NOW WE LOCATE THE POINT OF MINIMUM M AND ITS VALUE 'MINM'
C     AND STORE THE HEIGHT INDEX 'ITOP' AND THE THICKNESS OF THE LAYER 'DZ'

      MINM = MAXM
      DO 275 I_HT = I_MAXM , I_MAXM + 100
	 IF  (M_PROFILE(I_HT ) .LT. MINM ) THEN
	     MINM = M_PROFILE( I_HT )
	     DZ = 3*(I_HT-1) - BASE_HT
	     ITOP = I_HT				 	      
	 END IF	  
  275 CONTINUE
      MDEFF = MAXM - MINM


C     NOW WE TEST FOR WHETHER THE PROFILE IS REASONABLE OR NOT
C     CRITERION 1: THERE SHOULD BE NO POINTS IN THE PROFILE THAT ARE TO THE
C     RIGHT OF A STRAIGHT LINE AT A SLOPE OF .1 M-UNITS / METER WITHIN THE 
C     FIRST 100 METERS ABOVE THE BASE OF THE TRAPPING LAYER
C     CRITERION 2: WITHIN THE TRAPPING LAYER (BETWEEN I_MAXM AND ITOP) THERE
C     SHOULD BE NO POINTS TO THE RIGHT OF 'MAXM'	
	I_VALID = 1
	DO 280 I_HT = I_MAXM+3,I_MAXM+100 
	   IF (	M_PROFILE(I_HT) .GT. 
     *          (MAXM + (I_HT - I_MAXM)*.356 + 3.)) THEN ! criterion 1
	        I_VALID = 0
                write(*,*)' rejecting crit-1'
              goto 290
	   END IF
	   IF (( M_PROFILE( I_HT ) .GT. MAXM+1 ) .AND.
     *             (I_HT .LT. ITOP)) THEN        !criterion 2
	        I_VALID = 0
                write(*,*)' rejecting crit-2'
              goto 290
	   END IF	 
  280 CONTINUE
c     Criterion 3; for the 50 m below the base heigth 
C     there should not be a kink to the rigth.
      I_REF = I_BASE_HT - 17
      DO 300 I = I_REF + 1, (I_BASE_HT + 2)
         IF (M_PROFILE(I) .GT. (I - I_REF)*(.356 +0.10)+3
     *          +  M_PROFILE(I_REF)) THEN
            I_VALID = 0
               write(*,*)' rejecting crit-3'
            goto 290
         END IF
 300  CONTINUE

 290  return
 

	END



C     GEN_COEFFICIENTS GENERATES RANDOM COEFFICIENTS FOR NUISANCE PARAMETERS
C     IF 'I_GEN_NUISANCE' IS SET TO 1; OTHERWISE THE NUISANCE PARAMETER 
C     COEFFICIENTS ARE SET TO ZERO
	SUBROUTINE GEN_COEFFICIENTS( I_GEN_NUISANCE, EOF_S_SD,RQD_MDEFF )
	INTEGER  I_GEN_NUISANCE		
	REAL     EOF_S_SD(*)
	REAL     RQD_MDEFF

C     REFRACTIVITY PARAMETER VARIABLES
	REAL BASE_HT
	REAL MIXED_LAYER_SLOPE_DEV
	INTEGER NP 
	REAL CAP_INV_COEF(100)
	REAL FREE_TROPO_SLOPE_DEV
	COMMON / INPUT_PARAMS / BASE_HT , MIXED_LAYER_SLOPE_DEV,
     *         NP, CAP_INV_COEF, FREE_TROPO_SLOPE_DEV

C     WORKING VARIABLES
	INTEGER  I
	REAL ZZ, Z
	REAL RN(1)
	
      IF (NP .GE. 1) THEN 
	   DO 444 I=1,NP
	      CAP_INV_COEF(I)=CAP_INV_COEF(I)*EOF_S_SD(I)
  444    CONTINUE	 
      END	IF
      
C     WE NOW USE A UNIFORM RANDOM NUMBER GENERATOR TO GENERATE NUMBERS
C     HAVING A VARIANCE OF 1.0; SINCE VAR(UNIFORM) = (UPPER LIMIT - LOWER LIMIT)^2 / 12
C     THE LOWER AND UPPER LIMITS MUST BE -1.73 AND +1.73 RESPECTIVELY.
	
      IF (I_GEN_NUISANCE .EQ. 1) THEN
  	   DO 454 I=(NP+1),100
c	      CALL RNUN(1,RN)
	      ZZ = ran       !RN(1)
	      IF (I .LT. 4)	 THEN
	         IF ((RQD_MDEFF .LT. 10.0) .OR. (RQD_MDEFF .GT. 40)) THEN
	            Z=10. * (ZZ-.5) 
	         ELSE
                  Z=3.46 * (ZZ-.5) 
	         END IF
	      ELSE
	         Z=3.46 * (ZZ-.5) 
	      END IF
	      CAP_INV_COEF(I)=Z * EOF_S_SD(I)
  454    CONTINUE	
      ELSE
	   DO 464 I=(NP+1),100
	      CAP_INV_COEF(I)= 0.
  464    CONTINUE	
      END IF			   
      END




	SUBROUTINE LOAD_PARAMETERS
C     REFRACTIVITY PARAMETER COMMON VARIABLES
      REAL BASE_HT
	REAL MIXED_LAYER_SLOPE_DEV
	INTEGER NP
	REAL CAP_INV_COEF(100)
	REAL FREE_TROPO_SLOPE_DEV
    	COMMON / INPUT_PARAMS / BASE_HT , MIXED_LAYER_SLOPE_DEV,
     *         NP, CAP_INV_COEF, FREE_TROPO_SLOPE_DEV

        integer nc
        character*80  seof_dir
        common /seofdir/seof_dir,nc

      OPEN(UNIT=1,
     1  FILE=seof_dir(1:nc)//'param.dat')
c     1     ACTION='READ')
	READ(1,*)  BASE_HT,  MIXED_LAYER_SLOPE_DEV,
     *          ANUM_DETERMINISTIC, 
     * 		  CAP_INV_COEF(1),CAP_INV_COEF(2),CAP_INV_COEF(3),
     *          CAP_INV_COEF(4),CAP_INV_COEF(5),
     *		  FREE_TROPO_SLOPE_DEV	  
	CLOSE(1)
 	NP=INT(ANUM_DETERMINISTIC)		! NP - DETERMINISTIC TRAP LAYER PARS 
 	END



	SUBROUTINE GEN_M_PROFILE(HEIGHT_ARRAY, M_PROFILE)
	PARAMETER(N_HT_S=100,N_HT_B=100,N_HT_U=200,N_PRF_S=100)	   
C     ARRAYS FOR DATA INPUT
	REAL EOF_S( N_HT_S , N_HT_S+1 )
	REAL EOF_B( N_HT_B )
	REAL EOF_U( N_HT_U )
	REAL EOF_S_SD( N_HT_S )
	COMMON / EOF_ARRS / EOF_S , EOF_B , EOF_U , EOF_S_SD	 


C     OUTPUT ARRAYS
	REAL M_PROFILE(500)
	REAL HEIGHT_ARRAY(500)



C     REFRACTIVITY PARAMETER VARIABLES
 	REAL BASE_HT
	REAL MIXED_LAYER_SLOPE_DEV
	INTEGER NP 
	REAL CAP_INV_COEF(100)
	REAL FREE_TROPO_SLOPE_DEV
	COMMON / INPUT_PARAMS / BASE_HT , MIXED_LAYER_SLOPE_DEV,
     *         NP, CAP_INV_COEF, FREE_TROPO_SLOPE_DEV


	
C     WORKING VARIABLES    
      REAL HEIGHT_INC
	REAL DELTA
	INTEGER I_HT, I_ABOVE, I_BELOW
	

	HEIGHT_INC=3.

C       CONSTRUCT LOWER PORTION OF PROFILE BASED UPON
C       PARAMETERS BASE_HT AND MIXED_LAYER_SLOPE_DEV
C       NOTE: WE ARE WORKING WITH 3 METER HEIGHT INCREMENTS	   
	IF((BASE_HT .GT. 100.+HEIGHT_INC) 
     1    .AND. (BASE_HT .LT. 1400)) THEN

C        FIRST WE DO THE REGION FROM THE SURFACE TO 
C        WITHIN 100 METERS OF THE CAPPING INVERSION
C        ESSENTIALLY WE ARE JUST TAKING A SINGLE REALIZATION
C        AND SETTING THE PROFILE TO THAT AND ALLOWING A 
C        MEAN SLOPE ADJUSTMENT
	   I_TOP = INT((BASE_HT - 100.)/HEIGHT_INC)	
	   M_PROFILE(1) = 330.	 			! ASSUME A BASE M-UNIT VALUE OF 330
	   DO 1000 I_HT=2 , 500				! START AT THE SECOND HEIGHT NOW
	      HEIGHT_ARRAY(I_HT) = HEIGHT_INC * (I_HT - 1)
	      I_ABOVE = MOD( I_HT , (N_HT_B - 2) ) + 2 ! VARIES FROM 2 TO 100
	      I_BELOW = I_ABOVE - 1	! VARIES FROM 1 TO 99
	      DELTA = EOF_B(I_ABOVE)-EOF_B(I_BELOW) !THE CHANGE IN M IN 3 METERS
	      M_PROFILE(I_HT) = M_PROFILE(I_HT-1) + DELTA +
     *	       HEIGHT_ARRAY(I_HT) * MIXED_LAYER_SLOPE_DEV *
     *           HEIGHT_INC 
 1000    CONTINUE
C        NOW THE HEIGHT AND M_PROFILE ARRAYS ARE FILLED AS THOUGH
C        THE MIXED LAYER WENT UP TO 1497 METERS
	

C        NOW WE DO THE REGION FROM 100 METERS BELOW THE BASE HEIGHT 
C        OF THE CAPPING INVERSION, TO 200 METERS ABOVE THE BASE
C        HEIGHT OF THE CAPPING INVERSION
C        WE DO THIS BY CALCULATING THE CHANGE IN REFRACTIVITY FROM
C        (I_HT - 1) TO I_HT CALCULATED FROM THE THE EOF'S FOR THE
C        MIXED LAYER
C        NOTE: IN THE SOURCE FILES, THE MEAN PROFILE IS IN
C        'EOF_S00'; BUT ITS ARRAY INDEX IS 1
C        AND THE EOF ARE NUMBERED 2 TO 101	 
         DO 2200 I_HT = I_TOP+1 , I_TOP + N_HT_S - 1
	      I_ABOVE = I_HT - I_TOP + 1   ! START AT I=2
            I_BELOW = I_ABOVE -1         ! START AT 1=1	  
		  TMP_ABOVE = EOF_S(I_ABOVE,1) ! CONSTANT 
            TMP_BELOW = EOF_S(I_BELOW,1) ! CONSTANT	 
		  DO 2100 J = 2,100
		     TMP_ABOVE = TMP_ABOVE + CAP_INV_COEF(J-1) * 
     *                     EOF_S(I_ABOVE,J)				  
     		     TMP_BELOW = TMP_BELOW + CAP_INV_COEF(J-1) * 
     *                     EOF_S(I_BELOW,J)	
 2100       CONTINUE	   
            DELTA = TMP_ABOVE - TMP_BELOW
		  M_PROFILE(I_HT) = M_PROFILE(I_HT-1)+DELTA
 2200    CONTINUE
         I_TOP = I_HT - 1	   ! WE JUMP BACK ONE INCREMENT TO AVOID
	                       ! A DISCONTINUITY AT THE CONCANTANATION
						   ! POINT


C        NOW WE DO THE REGION ABOVE 200 METERS ABOVE THE CAPPING 
C        INVERSION. AT THIS POINT WE ARE 
C        JUST CONCATANATING A REALIZATION OF THE
C        FREE TROPOSPHERE TO THE M_PROFILE AT HEIGHT 'I_TOP'
	   DO 2400 I_HT = I_TOP + 1, 500				 	       
	      I_ABOVE = I_HT - I_TOP +1
	      I_BELOW = I_ABOVE - 1
	      IF (I_ABOVE .LE. N_HT_U ) THEN 
	         DELTA = EOF_U(I_ABOVE)-EOF_U(I_BELOW)
	         DELTA = DELTA + FREE_TROPO_SLOPE_DEV *
     *                 HEIGHT_INC 
	      ELSE
	         DELTA =  .354  ! ADD A STANDARD SLOPE FOR NEXT 3 METERS
		  END IF    								 		  
		  M_PROFILE(I_HT) = M_PROFILE(I_HT-1) + DELTA			   
 2400    CONTINUE				  
	ELSE
	   WRITE(*,*) 'ERROR -> BASE HEIGHT LESS THAN 100 METERS'
           stop
	END IF

 9999 CONTINUE

	END
      

	SUBROUTINE WRITE_M_FILE( HEIGHT_ARRAY, M_PROFILE )
	REAL HEIGHT_ARRAY(500),M_PROFILE(500)
	INTEGER I_HT
	OPEN(UNIT=2,
     1      FILE='test.dat')
c     ,ACTION='WRITE')
	DO 3000 I_HT=1,497,2
	   WRITE(2,3005) HEIGHT_ARRAY(I_HT),M_PROFILE(I_HT)
 3000	CONTINUE	  
	WRITE(2,3005) HEIGHT_ARRAY(I_HT)+500.,M_PROFILE(I_HT)+59.	
	CLOSE(2)
 3005 FORMAT(2F10.3)	 
	END  





C     FIRST WE LOAD THE EOF_Sxx FILES INTO STORAGE
C     NOTE THAT THE EOF_S(*,1) IS THE MEAN SLOPE
C     AND COMES FROM FILE EOF_S00	
	SUBROUTINE LOAD_EOF_S(  N_HT_S , EOF_S )
	REAL EOF_S(  N_HT_S , (N_HT_S + 1) )
	REAL HT
	CHARACTER*80 FN

        integer nc
        character*80  seof_dir
        common /seofdir/seof_dir,nc

	DO 15 IEOF = 1,99	
	   IF (IEOF .LT. 11) THEN
	      WRITE(FN,75)seof_dir(1:nc)//'eof_s0',IEOF-1
	   END IF
	   IF (IEOF .GT. 10) THEN
	      WRITE(FN,76)seof_dir(1:nc)//'eof_s',IEOF-1
	   END IF		

	   OPEN(UNIT=1,FILE=FN)
c,ACTION='READ')
	   DO 10 I=1,N_HT_S
	      READ(1,*) HT,EOF_S(I,IEOF)
   10	   CONTINUE
         CLOSE(1)	  	
   15 CONTINUE
   75	FORMAT(A,I1)
   76	FORMAT(A,I2) 
	END

C     NOW WE LOAD THE STANDARD DEVIATIONS OF THE EOF'S
C     FOR THE CAPPING REGION
	SUBROUTINE LOAD_EOF_S_SD(  N_HT_S , EOF_S_SD )
	REAL EOF_S_SD(  N_HT_S  )
	REAL EOF_NO

        integer nc
        character*80  seof_dir
        common /seofdir/seof_dir,nc
	

	OPEN(UNIT=1,FILE=seof_dir(1:nc)//'eofsig_s')
c     1       ACTION='READ')	   
	DO 35 IEOF = 1,100	
	   READ(1,*) EOF_NO,EOF_S_SD(IEOF)
   35	CONTINUE
      CLOSE(1)	  	
     	END	   



C     LOADING 'BOTTOM' REALIZATION
	SUBROUTINE LOAD_EOF_B(  N_HT_B ,  EOF_B )
	REAL EOF_B(  N_HT_B  )
	REAL HT
        integer nc
        character*80  seof_dir
        common /seofdir/seof_dir,nc
		
      OPEN(UNIT=1,FILE=seof_dir(1:nc)//'best_u')
c     1      ACTION='READ')
	DO 20 I=1,N_HT_B
	   READ(1,*) HT,EOF_B(I)					
   20	CONTINUE
      CLOSE(1)	  	
   	END
	 
C     LOADING 'UPPER' REALIZATION	
	SUBROUTINE LOAD_EOF_U(  N_HT_U ,  EOF_U )
	REAL EOF_U(  N_HT_U  )
	REAL HT

        integer nc
        character*80  seof_dir
        common /seofdir/seof_dir,nc
	
      OPEN(UNIT=1,FILE=seof_dir(1:nc)//'best_u')
c     1    ACTION='READ')
	DO 30 I=1,N_HT_U
	   READ(1,*) HT,EOF_U(I)					
   30	CONTINUE
      CLOSE(1)	  	
   	END

	 