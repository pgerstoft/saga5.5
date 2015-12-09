C
C   ********************************************************************
C   *                                                                  *
C   *  Copyright (c) Department of National Defence of Canada 1988     *
C   *                                                                  *
C   *  The computer software described herein is the sole property     *
C   *  of the Department of National Defence, Canada.                  *
C   *                                                                  *
C   *  Its use or distribution, in whole or in part, is not permitted  *
C   *  without written authorization by the Department.                *
C   *                                                                  *
C   *  Requests should be forwarded to:                                *
C   *           Chief                                                  *
C   *           Defence Research Establishment Atlantic                *
C   *           P.O. Box 1012                                          *
C   *           Dartmouth, Nova Scotia, Canada                         *
C   *           B2Y 3Z7                                                *
C   *                                                                  *
C   *  The Department assumes no express or implied liability          *
C   *  resulting from use of this software.                            *
C   *                                                                  *
C   ********************************************************************
C
C  SUBPROGRAM: MODES
C  PURPOSE:    NORMAL MODE WAVE NUMBERS AND MODE FUNCTIONS FOR AN
C              ARBITRARY SOUND SPEED AND DENSITY PROFILE
C  LANGUAGE:   FORTRAN
C  AUTHORS:    BRIAN LEVERMAN AND DALE D ELLIS  -- SUMMER 1978
 
C MODIFICATIONS:
C   1978-1982:  Various modifications by Dale Ellis
C   Jun-Aug-82: Fortran V.6 updates, and some bug fixes.
C               AESD test cases.  By Mark Radcliffe.
C   19-Jul-84: Depth-dependent attenuation for Ian Fraser (FMODES)
C   18-Dec-84: Bug corrections, attenuation common, and group velocities
C         -86: VAX conversion ?
C    5-Apr-88: FMODES + ATTENU(FMODES.FOR) + OUTPUT(NEWMOD.FOR)
C    6-Apr-88: Fix METHOD=1/METHOD=2 oscillation in MODES
C   31-Oct-88: PLTSUB shortened format statements
C    2-Nov-88: DATACK changed errors on output unit
C    1-Jun-89: Date of record for changes relating to CANARPS and REVERB,
C              Terry J. Deveau
C    5-Oct-89: Made to conform to ANSI standard FORTRAN.  Terry J. Deveau
C LAST EDIT: 5-Oct-89
C
 
C REFERENCES:
C   Brian Leverman and Dale D. Ellis, "Software documation for normal
C     modes subprogram: MODES", DREA Research Note, AM/82/4, June 1982.
C   Brian Leverman, "Users guide to normal mode propagation loss
C     package PROLOS", DREA Research Note, AM/82/3, June 1982.
C   Dale D. Ellis, "A two-ended shooting technique for calculating
C     normal modes in underwater acoustic propagation", D.R.E.A.
C     Report 85/105, September 1985.
C   Terry J. Deveau, "Enhancements to the PROLOS Normal-mode
C     Acoustic Propagation Model", DREA Contractor Report CR/89/?,
C     June 1989
 
C CONTENTS:
C     MODES     ERROR    INTIN    LINEAR
C     ATTENU    QTRIAL   XMATCH   LAYER
C     ATTDEP    TURNPT   NORMAL   PLTSUB
C     DATACK    INTPTS   ITPDAT   KIRKFF
C     DOPAR     INTOUT   OUTPUT   KIRKFB
 
      SUBROUTINE OMODES (NWL,ZP,CP,BH,H,NBL,HBOT,CBOT,ALPBT,RHO,
     1    ROUGH,NS,NR,ZS,ZR,NL,ZI,CI,FREQ,MAXNM,NMODES,LOWER,NMCAL,
     2    WORK,KND,KNI,UN,MAXNL,AMPL,PHSE,PRTKNI,PRTKNB,
     3    PRTWAT,PRTSED,PRTSUB,PRTGVL,IERR)
 
      INTEGER I,ICNT1,ICNT2,IEF,IERR,INDEX,ISR(25),ITMAX,MAXNL,IUPPER,J,
     1    K,LOWER,METHOD,NBL,NL,NMCAL,NMIN,NPT,NR,NS,NSR,NWATL,NWL,
     2    NZC,NZCPV,NZCQ1,NMODES,Z1,Z2,ZA,ZB,ZAQ1,ZBQ1,ZM,HOLZA, HOLZB,
     3    HOLNZC,MAXNM
      REAL KNI(NMODES),TOLGAM,TOLK,BH,RHO(0:NBL),ALPBT(NBL),ATNBOT,
     1    ATNSED,ATNSHR,ATNSUB,ATNSUR,ATNWAT,CBOT(NBL),CP(NWL),
     2    DELKNB,DELKNI,DELOUT,FREQ,GRPVEL,H,HBOT(NBL),RHO1,RK0SQ,RK1SQ,
     3    RKN,UN(MAXNM,*),UNPZ,UNPZH,UNZH,VMAX,VMIN,ZMX,ZP(NWL),ZR(NR),
     4    ZS(NS),AMPL(MAXNL,NMODES),PHSE(MAXNL,NMODES),ROUGH(0:NBL),
     5    PRTKNI(NMODES),PRTKNB(NMODES),PRTWAT(NMODES),PRTSED(NMODES),
     6    PRTSUB(NMODES),PRTGVL(NMODES),TOLU,SIG0,SIG1
      DOUBLE PRECISION WORK(NL,2),SMOUT,SMIN,UOUT,UDROUT,UIN,UDRIN,
     1    Q,Q1,Q2,DELQ,DELQPV,ZI(NL),CI(NL),CMIN,CMAX,OMEGA,KND(NMODES),
     2    FACTOR,HH,SUMA,SUMB,SR(25)
 
      COMMON /PAR/    VMIN,VMAX,NMIN,ITMAX,IEF
      COMMON /TOL/    TOLK,TOLU,TOLGAM
 
      COMMON /DATA/   OMEGA,CMIN,CMAX
      COMMON /ATTENS/ ATNWAT,ATNSED,ATNSUB,ATNSUR,ATNBOT,ATNSHR,GRPVEL
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C       NORMAL MODE SUBROUTINE
C
C               WRITTEN BY: BRIAN LEVERMAN
C               DEFENCE RESEARCH ESTABLISHMENT ATLANTIC
C                 DARTMOUTH,NOVA SCOTIA,CANADA
C               UNDER THE SUPERVISION AND ASSISTANCE OF:
C                       DR. DALE D. ELLIS
C                       DURING: MAY TO AUGUST , 1978
C               WRITTEN ON:  DEC-20/40,OPERATING SYSTEM: TOPS-20
C                       LANGUAGE: FORTRAN IV
C                       PRECISION: INPUT/OUTPUT-SINGLE
C                                : INTERNALLY-SINGLE/DOUBLE
C
C
C       FUNCTION:
C          THE SUBROUTINE MODES CALCULATES THE EIGENVALUES AND
C       EIGENFUNCTIONS WHICH ARE THE DISCRETE SOLUTIONS OF THE
C       ACOUSTIC WAVE EQUATION IN THE CONTEXT OF UNDERWATER ACOUSTICS
C       AS WELL AS THE ATTENUATION OF THESE EIGENFUNCTIONS.
C       THE SUBROUTINE USES AN ARBITARY VELOCITY PROFILE IN THE
C       WATER COLUMN AND A LAYERED BOTTOM.
C
C       SUBROUTINES CALLED BY NMODES:
C
C       DATACK,ITPDAT,DOPAR,QTRIAL,TURNPT,INTPTS,INTOUT,INTIN,NORMAL,
C       OUTPUT,ATTENU,ERROR, KIRKFF,KIRKFB
C
C       FUNCTIONS CALLED BY NMODES:
C
C       XMATCH
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C
C       NOTES FOR THIS SUBROUTINE:
C         TWO METHODS ARE USED TO CONVERGE TO AN ACCEPTABLE EIGENVALUE
C        FIRST A HALVING METHOD UNTIL THE VALUE OF Q IS REASONABLY
C        CLOSE AND THEN A SECOND ORDER METHOD TO COMPLETE THE
C        ITERATION TO THE PROPER EIGENVALUE
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C IMPORTANT VARIABLES:
C
C       PARAMETERS USED IN INPUT/OUTPUT OPERATIONS:
C
C
C       INPUT(ARGUMENT LIST): (ALL SINGLE PRECISION)
C
C       NWL: THE INPUT NUMBER OF POINTS IN THE INPUT VELOCITY PROFILE
C       ZP(NWL): THE DEPTHS IN THE VELOCITY PROFILE (DEPTH=0 AT THE
C          WATER SURFACE,AND IS POSITIVE AT GREATER DEPTHS)
C       CP(NWL): THE SOUND SPEED AT EACH OF THE ABOVE DEPTHS
C       H: THE DEPTH OF THE WATER COLUMN
C       NBL: THE NUMBER OF BOTTOM LAYERS SPECIFIED
C       HBOT(NBL): THE HEIGHT OF EACH BOTTOM LAYER
C       CBOT(NBL): THE SPEED OF SOUND IN EACH BOTTOM LAYER
C       ALPBT(NBL): THE ATTENUATION IN EACH BOTTOM LAYER
C       RHO(0:NBL): CONTAINS ALL THE DENSITY INFORMATION.
C          RHO(0) is the density in the water column and the remaining
C          NBL values are density in each sediment layer
C       NS: THE NUMBER OF SOURCES OF SOUND
C       ZS(NS): THE DEPTH OF EACH OF THESE SOURCES
C       NR: THE NUMBER OF RECEIVERS SPECIFIED
C       ZR(NR): THE DEPTHS OF THESE RECEIVERS
C       FREQ: THE FREQUENCY OF THE SOURCE OF SOUND
C       NMODES: THE MAXIMUM NUMBER OF MODES TO BE CALCULATED
C       MAXNM: THE FIRST DIMENSION OF ARRAY UN IN THE CALLING ROUTINE
C       NL: THE SUM OF NBL AND THE NUMBER OF LAYERS YOU WISH TO
C          USE IN THE WATER COLUMN WHEN THE INPUT VELOCITY PROFILE
C          IS INTERPOLATED
C       NSR: NS+NR
C
C       VMIN: A PHASE VELOCITY , ANY EIGENFUNCTION CORRESPONDING TO A
C          PHASE VELOCITY BELOW VMIN WILL NOT BE CALCULATED,
C          DEFAULT VALUE=CMIN
C       VMAX: A PHASE VELOCITY , ANY EIGENFUNCTION CORRESPONDING TO A
C          PHASE VELOCITY GREATER THAN VMAX WILL NOT BE CALCULATED,
C          DEFAULT VALUE=CMAX
C       NMIN: THE FIRST EIGENFUNCTION TO BE CALCULATED, DEFAULT
C          VALUE=1
C       ITMAX: THE MAXIMUM NUMBER OF ITERATIONS ALLOWED IN THE
C          CALCULATION OF EACH EIGENFUNCTION IN EITHER PART OF THE
C          TWO PART PROCEDURE, DEFAULT VALUE=30
C       IEF: THE DEVICE NUMBER TO WHICH ALL ERROR OR WARNING MESSAGES
C          AS WELL AS OPTIONAL PRINTING OUTPUTS WILL BE DIRECTED
C       TOLK: THE TOLERANCE ON THE EIGENVALUE , DEFAULT VALUE=1.0E-8
C       TOLU: THE MINIMUM ALLOWABLE SIZE OF THE EIGENVALUE AT THE
C          MATCHING RADIUS , DEFAULT VALUE=1.0E-4
C       TOLGAM: THE MINIMUM ALLOWABLE SIZE OF GAMMA BEFORE A LINEAR
C          SOLUTION IS USED IN THE LAYER , DEFAULT VALUE=1.0E-4
C
C       OUTPUT: (ALL SINGLE PRECISION)
C
C       LOWER: THE NUMBER OF ZERO CROSSINGS FOR THE FIRST MODE
C          ACTUALLY CALCULATED
C       NMCAL: THE NUMBER OF MODES ACTUALLY CALCULATED
C       KND(NMODES): THE EIGENVALUES CALCULATED (DOUBLE PRECISION VARIABLE)
C       KNI(NMODES): THE ATTENUATIONS OF THE EIGENFUNCTIONS (REAL VARIABLE)
C       UN(MAXNM,NSR): THE EIGENFUNCTIONS EVALUATED AT ALL SOURCE AND
C       RECEIVER DEPTHS
C       IERR: THE ERROR FLAG 0=>NO ERRORS OR WARNINGS HAVE BEEN ISSUED
C          1=>FATAL ERROR HAS OCCOURED EXECUTION HALTED,ALSO
C          WARNINGS MAY HAVE BEEN ISSUED BEFORE THE FATAL ERROR
C          2=>NO FATAL ERRORS BUT AT LEAST 1 WARNING HAS BEEN ISSUED
C
C       VARIABLES IN ARGUMENT LIST USED INTERNALLY: (ALL DOUBLE
C                                                   PRECISION)
C
C       ZI(NL): CONTAINS THE DEPTH, NORMALIZED SO THAT H=1, WHERE
C          EACH OF THE NL LAYERS BEGINS FOR THE INTERPOLATED PROFILE
C       CI(NL): CONTAINS THE AVERAGE OF THE TOP AND BOTTOM VELOCITIES
C          IN EACH OF THE ABOVE LAYERS , TRANSFORMED TO
C          H**2*OMEGA**2/SPEED**2. THE LAST NBL ENTRIES CONTAIN
C          INFORMATION FROM THE BOTTOM LAYERS, THE FIRST NL-NBL
C          LAYERS CONTAIN INFORMATION FROM THE INPUT VELOCITY
C          PROFILE INTERPOLATED LINEARLY
C       WORK(NL,2): THE MATRIX IS USED TO CONTAIN THE EIGENFUNCTION
C          (IN WORK(*,1))AND ITS DERIVATIVE (IN WORK(*,2))AS IT
C          IS BEING CALCULATED. THE VALUE STORED IN POSITION I IS
C          THE VALUE OF THE EIGENFUNCTION AND ITS DERIVATIVE JUST
C          BELOW THE UPPER BOUNDRY OF LAYER I.
C
C
C       PARAMETERS USED INTERNALLY AND NOT APPEARING IN INPUT/OUTPUT
C          OPERATIONS: (ALL REAL VARIABLES ARE DOUBLE PRECISION
C                       EXCEPT ZMX,DELIN,DELOUT)
C
C       NZCQ1: THE NUMBER OF ZERO CROSSINGS IF THE TRIAL EIGENVALUE
C          WERE EQUAL TO Q1 WHICH IS THE LOWER BOUND ON THE EIGENVALUE
C       ZAQ1: THE POINT AT WHICH THE OUTWARDS INTEGRATION BEGINS IF THE
C          TRIAL EIGENVALUE  WERE EQUAL TO Q1, USE THIS VALUE WHEN USING
C          THE SECOND ORDER METHOD (INTEGER)
C       ZBQ1: THE POINT AT WHICH THE INWARDS INTEGRATION BEGINS IF THE
C          TRIAL EIGENVALUE WERE EQUAL TO Q1, USE THIS VALUE WHEN USING
C          THE SECOND ORDER METHOD (INTEGER)
C       ICNT1: ITERATION COUNTER FOR THE HALVING METHOD
C       ICNT2: ITERATION COUNTER FOR THE SECOND ORDER METHOD
C       OMEGA: 2*PI*FREQUENCY
C       CMIN: (H*OMEGA/MINIMUM SOUND SPEED)**2
C       CMAX: (H*OMEGA/SPEED IN LOWEST BOTTOM LAYER)**2
C       NPT: THE NUMBER OF LAYERS IN THE WATER COLUMN USED IN THE
C          INTERPOLATION, NPT=NL-NBL
C       Q: A TRIAL EIGENVALUE
C       Q1: A LOWER BOUND ON AN EIGENVALUE
C       Q2: AN UPPER BOUND ON AN EIGENVALUE
C       NZC: THE NUMBER OF ZERO CROSSINGS OF A TRIAL EIGENFUNCTION
C       DELQ: THE CHANGE IN A TRIAL EIGENVALUE Q TO BE USED TO
C          DETERMINE THE NEXT VALUE FOR Q TO BE TESTED WHEN THE NUMBER
C          OF ZERO CROSSINGS IS CORRECT
C       Z1: THE LAYER WHERE THE UPPER TURNING POINT IS LOCATED (INTEGER)
C       Z2: THE LAYER WHERE THE LOWER TURNING POINT IS LOCATED (INTEGER)
C       SUM=THE MAXIMUM VALUE ALLOWED IN THE SUM TO DETERMINE THE
C          POINTS AT WHICH THE INTEGRATIONS START
C       SUMA: THE SUM WHICH DETERMINES THE POINT AT WHICH THE OUTWARDS
C          INTEGRATION STARTS
C       SUMB: THE SUM WHICH DETERMINES THE POINT AT WHICH THE INWARDS
C          INTEGRATION STARTS
C       ZA: THE LAYER IN WHICH THE OUTWARDS INTEGRATION STARTS (INTEGER)
C       ZB: THE LAYER IN WHICH THE INWARDS INTEGRATION STARTS (INTEGER)
C       ZM: LAYER IN WHICH MATCHING RADIUS IS CONTAINED (INTEGER)
C          THIS IS THE LAYER CONTAINING THE MINIMUM SOUND SPEED
C       SMOUT: THE INTEGRAL, OF THE EIGENFUNCTION SQUARED
C          DIVIDED BY DENSITY, FROM THE SURFACE TO THE MATCHING
C          RADIUS
C       SMIN: THE INTEGRAL, OF THE EIGENVALUE SQUARED DIVIDED BY
C          DENSITY , FROM THE MATCHING RADIUS TO POSITIVE INFINITY
C       GAMMA2: CI(I)-Q
C       GAMMA: SQUARE ROOT(ABSOLUTE VALUE(GAMMA2))
C       ICHS: CHANGE OF SIGN OF THE EIGENFUNCTION IN A LAYER
C          1=>CHANGE OF SIGN, 0=>NO CHANGE OF SIGN
C       IZX: INTEGER PART OF, GAMMA * LAYER HEIGHT / PI
C       ZMX: ACTUAL LOCATION OF MATCHING RADIUS IN LAYER ZM
C          STORED AS A VALUE BETWEEN ZERO AND THE DEPTH OF THE LAYER
C       DELIN: THE ARCTAN OF, THE EIGENFUNCTION DIVIDED BY ITS
C          DERIVATIVE DIVIDED BY THE DENSITY IN THE LAYER,
C          USING THE VALUES FROM THE LAST LAYER IN THE INWARDS
C          INTEGRATION
C       DELOUT: SAME AS ABOVE EXCEPT FROM THE OUTWARDS
C          INTEGRATION
C       UIN: THE VALUE OF THE EIGENFUNCTION AT THE MATCHING RADIUS
C          FROM THE INWARDS INTEGRATION
C       UDRIN: THE VALUE OF THE DERIVATIVE OF THE EIGENFUNCTION
C          AT THE MATCHING RADIUS FROM THE INWARDS INTEGRATION
C       UOUT: THE VALUE OF THE EIGENFUNCTION AT THE MATCHING RADIUS
C          FROM THE OUTWARDS INTEGRATION
C       UDROUT: THE VALUE OF THE DERIVATIVE OF THE EIGENFUNCTION
C          AT THE MATCHING RADIUS FROM THE OUTWARDS INTEGRATION
C       ISR(25): CONTAINS THE LAYER NUMBER OF THE LAYER CONTAINING EACH
C          SOURCE AND RECEIVER DEPTH FOR ALL THE SOURCES AND RECEIVERS
C          OR THE FIRST 25
C       SR(25): CONTAINS THE ACTUAL POSITION OF THE SOURCE OR RECEIVER
C          DEPTH IN THEIR RESPECTIVE LAYERS FOR ALL THE SOURCES AND
C          RECEIVERS OR THE FIRST 25
C       LOWER: EIGENVALUE NUMBER OF THE FIRST EIGENVALUE AND
C          EIGENFUNCTION TO BE CALCULATED
C       IUPPER: EIGENVALUE NUMBER OF THE LAST EIGENVALUE AND
C          EIGENFUNCTION TO BE CALCULATED
C       IERR: THE ERROR FLAG , IERR=0=> NO ERROR , IERR=1=>AN ERROR
C          HAS BEEN TRAPED,AN ERROR MESSAGE OUTPUTED,EXECUTION
C          STOPPED , ALSO WARNING MESSAGES MAY HAVE BEEN ISSUED ,
C          IERR=2=>A WARNING MESSAGE OUTPUTED , EXECUTION CONTINUED
C       FACTOR: THE RATIO OF THE VALUES OF THE EIGENFUNCTION AT THE
C          MATCHING RADIUS FROM THE INWARDS AND THE OUTWARDS
C          INTEGRATION
C       METHOD: FLAG TO INDICATE WHICH METHOD IS IN USE
C          METHOD=1=>THE HALVING OR BISECTION METHOD IS IN CURRENT USE
C          METHOD=2=>THE SECOND ORDER CORRECTION METHOD IS IN USE
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C       SET THE ERROR FLAG
C
      IERR=0
C
C       EXAMINE THE INPUT DATA FOR ERRORS
C
      NSR = NS + NR
      CALL DATACK(ZP,CP,NWL,BH,HBOT,CBOT,RHO,ALPBT,NBL,
     2ZS,ZR,NS,NR,NSR,NL,FREQ,NMODES,IERR)
      IF(IERR.EQ.1)RETURN
C
C       INTERPOLATE THE INPUT VELOCITY PROFILE AND ORGANIZE THE OTHER
C        INPUT DATA
C       FIND THE LAYER CONTAINING THE MATCHING RADIUS
C
      CALL ITPDAT(ZP,CP,NWL,H,FREQ,HBOT,CBOT,NBL,NL,
     2NSR,NS,NR,ZS,ZR,ZI,CI,NPT,ZM,ISR,SR,IERR)
      IF(IERR.EQ.1)RETURN
C
C       DETERMINE THE PARAMETERS FOR THE DO-LOOP WHICH CALCULATES THE
C        EIGENVALUES SO THAT THE EIGENVALUES REQUESTED ARE CALCULATED
C        IF THEY EXIST
C
      CALL DOPAR(ZI,CI,NL,H,NPT,ZM,RHO,NBL,NMIN,NMODES,LOWER,
     2IUPPER,WORK,IERR)
      IF(IERR.EQ.1)RETURN
C
C
C       CALCULATE THE EIGENFUNCTIONS & EIGENVALUES
C
C
      NMCAL=0
      DO 200 I=LOWER,IUPPER
      METHOD=1
      NZC=-2
      ICNT1=0
      ICNT2=0
      NZCPV=0
      DELQ=0.0
      Q=0.0
      Q1=0.0
      Q2=0.0
      K=I
C
C       OBTAIN A TRIAL VALUE FOR THE EIGENVALUE (Q)
C       INCREMENT AND CHECK THE ITERATION COUNTER FOR THE HALVING METHOD
C
  110 ICNT1=ICNT1+1
      IF(ICNT1.LE.ITMAX)GO TO 113
      CALL ERROR(1,IERR,FLOAT(ITMAX),FLOAT(K),0.0)
      GO TO 150
  113 CALL QTRIAL(NZC,K,DELQ,KND,NMODES,NZCQ1,ZA,ZAQ1,ZB,ZBQ1,Q,Q1,Q2,
     2LOWER,IERR)
      IF(IERR.EQ.1)RETURN
C
C       IF THIS IS THE FIRST ITERATION FOR THIS MODE CALCULATE THE
C        NUMBER OF ZERO CROSSINGS AND THE INTEGRATION POINTS
C        FOR Q1
C
      IF(ICNT1.NE.1)GO TO 115
      CALL TURNPT(-1,ZI,CI,NL,Q1,Z1,Z2,ZM,IERR)
      IF (IERR.EQ.1)  WRITE (IEF,*) CMAX,CMIN,Q1
      IF(IERR.EQ.1)RETURN
      CALL INTPTS(ZI,CI,NL,Z1,Z2,Q1,ZA,ZB,SUMA,SUMB,IERR)
      IF(IERR.EQ.1)RETURN
      CALL INTOUT(ZI,CI,NL,NPT,Q1,ZM,ZA,Z1,RHO,NBL,SUMA,WORK,SMOUT,
     1 NZC,DELOUT,IERR)
      IF(IERR.EQ.1)RETURN
C
      CALL INTIN(K,ZI,CI,NL,NPT,Q1,ZM,ZB,Z2,RHO,NBL,SUMB,WORK,SMOUT,
     2 DELOUT,NZC,ZMX,SMIN,UIN,UDRIN,UOUT,UDROUT,0,IERR)
      IF(IERR.EQ.1)RETURN
      CALL NORMAL(UOUT,UDROUT,UIN,UDRIN,SMIN,SMOUT,RHO,NBL,ZM,NPT,
     2FACTOR,DELQ,IERR)
      IF(IERR.EQ.1)RETURN
      NZCQ1=NZC
      ZAQ1=ZA
      ZBQ1=ZB
      IF(NZCQ1.LT.K.OR.NZCQ1.EQ.K.AND.DELQ.LT.0.0D0)
     2 CALL ERROR(43,IERR,FLOAT(K),REAL(Q1),FLOAT(NZCQ1))                 VMODES
      IF(IERR.EQ.1)RETURN
C
C       FIND THE TURNING POINTS FOR THE TRIAL EIGENVALUE Q
C
  115 CALL TURNPT(K,ZI,CI,NL,Q,Z1,Z2,ZM,IERR)
      IF(IERR.EQ.1)RETURN
C
C       CALCULATE THE POINTS AT WHICH TO BEGIN THE INTEGRATIONS
C
      CALL INTPTS(ZI,CI,NL,Z1,Z2,Q,ZA,ZB,SUMA,SUMB,IERR)
      IF(IERR.EQ.1)RETURN
C
C       PREFORM THE OUTWARDS INTEGRATION
C       COUNT THE NUMBER OF ZERO CROSSINGS
C
  120 NZCPV=NZC
      CALL INTOUT(ZI,CI,NL,NPT,Q,ZM,ZA,Z1,RHO,NBL,SUMA,WORK,SMOUT,
     2NZC,DELOUT,IERR)
      IF(IERR.EQ.1)RETURN
C
C       PREFORM THE INWARDS INTEGRATION
C       COUNT THE NUMBER OF ZERO CROSSINGS
C       DETERMINE THE MATCHING RADIUS AND THE VALUES OF THE
C        EIGENFUNCTION FROM THE INWARDS AND OUTWARDS INTEGRATION AT
C        THIS POINT
C
      CALL INTIN(K,ZI,CI,NL,NPT,Q,ZM,ZB,Z2,RHO,NBL,SUMB,WORK,SMOUT,
     2 DELOUT,NZC,ZMX,SMIN,UIN,UDRIN,UOUT,UDROUT,NZCPV,IERR)
      IF(IERR.EQ.1)RETURN
C
C       IF THE NUMBER OF ZERO CROSSINGS ARE NOT CORRECT GO BACK TO
C        OBTAIN A NEW TRIAL EIGENVALUE Q
C       IF THE NUMBER OF ZERO CROSSINGS ARE CORRECT SAVE DELQ FROM
C        THE PREVIOUS ITERATION
C
      IF(NZC.EQ.I)GO TO 116
C 7-Apr-88/DDE 6 lines
      IF (METHOD.EQ.2) THEN
        Q = Q - DELQ
        ZA = HOLZA
        ZB = HOLZB
        NZC = HOLNZC
      ENDIF
      FACTOR=UIN/UOUT
      UOUT=UOUT*FACTOR
      UDROUT=UDROUT*FACTOR
      SMOUT=SMOUT*FACTOR**2
      METHOD =1
      GO TO 110
  116 DELQPV=DELQ
C
C       NORMALIZE THE EIGENFUNCTION AT THE MATCHING RADIUS
C       CALCULATE DELQ
C
      CALL NORMAL(UOUT,UDROUT,UIN,UDRIN,SMIN,SMOUT,RHO,NBL,ZM,NPT,
     2FACTOR,DELQ,IERR)
      IF(IERR.EQ.1)RETURN
C
C       IF THE HALVING METHOD IS IN USE CHECK IF THE CONDITIONS ARE
C        MET FOR STARTING THE SECOND ORDER METHOD , IF NOT CONTINUE WITH
C        METHOD ONE
C
      IF(METHOD.EQ.2)GO TO 130
      Q=Q+DELQ
      IF(Q.GT.Q1.AND.Q.LT.Q2.AND.NZC.EQ.NZCQ1)GO TO 117
      Q=Q-DELQ
      GO TO 110
  117 METHOD=2
        HOLZA = ZA
        HOLZB = ZB
        HOLNZC = NZC
      ZA=ZAQ1
      ZB=ZBQ1
      GO TO 120
C
C       IF IN THE SECOND ORDER METHOD INCREMENT THE ITERATION COUNTER ,
C        CHECK FOR THE DESIRED ACCURACY IN Q , AND SEE IF A JUMP BACK
C        TO THE FIRST METHOD SHOULD BE MADE
C
  130 ICNT2=ICNT2+1
C       IF(DABS(DELQ/Q).LT.TOLK.AND.DABS(DELQ).GE.DABS(DELQPV))GO TO 150
      IF(DABS(DELQ/Q).LT.TOLK) GO TO 150
      IF(ICNT2.LT.ITMAX)GO TO 135
      CALL ERROR(2,IERR,FLOAT(ITMAX),FLOAT(K),0.0)
      GO TO 150
  135 Q=Q+DELQ
      IF(Q.GT.Q1.AND.Q.LT.Q2.AND.NZC.EQ.NZCQ1)GO TO 120
      Q=Q-DELQ
      METHOD=1
      GO TO 110
C
C       WHEN THE VALUE OF Q IS ACCURATE ENOUGH , NORMALIZE THE
C        EIGENFUNCTION , CALCULATE THE EIGENFUNCTION AT THE SOURCE AND
C        RECEIVER DEPTHS , OUTPUT OPTIONAL PLOTS OR PRINTS , AND
C        CALCULATE THE ATTENUATION OF THE EIGENFUNCTION
C
  150 CALL OUTPUT(K,ZI,CI,NL,NPT,H,Q,WORK,SMOUT,SMIN,FACTOR,NSR,ZS,NS,
     2    ZR,NR,ZM,ZMX,KND,ISR,SR,UN,NMODES,MAXNM,LOWER,IUPPER,NMCAL,
     3    NWL,ZP,CP,NBL,HBOT,CBOT,RHO,ALPBT,FREQ,MAXNL,AMPL,PHSE,IERR)
      IF(IERR.EQ.1)RETURN
C
C          CALCULATE ATTENUATION DUE TO BOTTOM ABSORPTION
C  [ NOTE THAT WORK(xx,2) NEEDS TO BE DIVIDED BY H TO GIVE THE DERIVATIVE. ]
      HH=DBLE(H)
      INDEX = I - LOWER + 1                                              7/07/82
      CALL ATTENU(K,ZI,CI,WORK(1,1),WORK(1,2),NL,ZA,ZB,ALPBT,
     1 RHO,NBL,Q,HH,FREQ,KNI(INDEX),IERR)                                7/07/82
      PRTWAT(INDEX) = ATNWAT
      PRTSED(INDEX) = ATNSED
      PRTSUB(INDEX) = ATNSUB
      PRTGVL(INDEX) = GRPVEL
      IF(IERR.EQ.1)RETURN
C
C          CALCULATE ATTENUATION DUE TO SURFACE SCATTERING (10/07/79)
      RK0SQ = CI(1)/HH**2
      RKN =SQRT(Q) / HH
      RHO1=RHO(0)
      UNPZ=WORK(1,2)/HH
      SIG0=ROUGH(0)
      CALL KIRKFF (SIG0,RHO1,UNPZ,RKN,RK0SQ,DELKNI)
C         IF (IER...
      KNI(INDEX) = KNI(INDEX) + DELKNI                                   7/07/82
      PRTKNI(INDEX) = DELKNI
C
C          CALCULATE ATTENUATION DUE TO BOTTOM ROUGHNESS (27/04/80)
      NWATL = NL-NBL
      RK1SQ = CI(NWATL)/HH**2
C       RKN = SQRT(Q) / HH
C       RHO1= RHO(0)
      UNZH = WORK (NWATL+1,1)
      UNPZH= WORK(NWATL+1,2)/HH * RHO(0)/RHO(1)
      SIG1 = ROUGH(1)
      CALL KIRKFB (SIG1,RHO1,UNZH,UNPZH,RKN,RK1SQ,DELKNB)
C         IF (IER....)
      KNI(INDEX) = KNI(INDEX) + DELKNB                                   7/07/82
      PRTKNB(INDEX) = DELKNB
C
  200 CONTINUE
C
C       BEFORE RETURNING TO THE CALLING PROGRAM TRANSFORM THE
C        EIGENVALUES TO THE REQUIRED DIMENSIONS
C
      HH=DPROD(H,H)
      DO 300 J=1,NMCAL
  300 KND(J)=SQRT(KND(J)/HH)
      RETURN
      END