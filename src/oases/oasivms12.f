      SUBROUTINE SPULSE(FREQS,DT,NX,LX,MX)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
      REAL FFS(2,NP)
      EQUIVALENCE (CFFS(1),FFS(1,1))
      CALL STERM(FREQS,DT,NX)
      CALL RFFT(CFFS,NX,1)
      CALL RFFTSC(CFFS,NX,1,1)
      CALL CVFILL(CNUL,CFF,2,NX/2)
C     CALL HANN(FFS(1,LX),2,FFS(1,LX),2,MX-LX+1,1)
C     CALL HANN(FFS(2,LX),2,FFS(2,LX),2,MX-LX+1,1)
      CALL CVMOV(CFFS(LX),2,CFF(LX,1),2,MX-LX+1)
      IF (LX.EQ.2) CFF(1,1)=CFFS(1)
      CALL RFFT(CFF,NX,-1)
      RETURN
      END
      SUBROUTINE STERM(FREQS,DELTAT,NX)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
      DIMENSION FF(NP2),AA(3)
      EQUIVALENCE (CFFS(1),FF(1))
      DATA AA /-.48829,.14128,-.01168/
      IF (ISTYP.GT.0) THEN
      TPF=2.0*PI*FREQS                  
      IF (ISTYP.NE.2) THEN
      OFR=1.0/FREQS       
      ELSE
      OFR=1.55/FREQS
        SUM0=-AA(1)-4*AA(2)-9*AA(3)
      END IF              
      FF(1)=0.0     
      DO 25 M=2,NX  
      TM=(M-1)*DELTAT                   
      FF(M)=0.0     
      GOTO (10,20,30,40,50),ISTYP          
 10   IF (TM.LE.OFR) FF(M)=.75-COS(TM*TPF)+.25*COS(2*TM*TPF)
      GO TO 25      
 20   IF (TM.LE.OFR) THEN
        SUM=0.
        DO 21 IHH=1,3
        SUM=SUM-AA(IHH)*IHH*IHH*COS(2*PI/OFR*IHH*TM)
 21     CONTINUE
        FF(M)=SUM
      END IF
      GO TO 25      
 30    IF (TM.LE.OFR) FF(M)=SIN(TPF*TM) 
      GO TO 25      
 40   IF (TM.LE.(4*OFR)) FF(M)=SIN(TPF*TM)*.5*(1-COS(TPF*TM/4.))                
      GO TO 25
 50   IF (TM.LE.OFR) FF(M)=SIN(TPF*TM)-.5*SIN(2*TPF*TM)
 25   CONTINUE            
      ELSE
        CALL VCLR(FF,1,NX)
        READ(66,*,END=60) (FF(M),M=1,NX)
 60     CONTINUE
      END IF              
      RETURN        
      END           
      SUBROUTINE INTGRN(NFLAG)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
      INCLUDE 'combes.f'
      COMPLEX FILON
      COMPLEX CSFAC
      LOGICAL NFLAG
      REAL CBR(2,NP)
      EQUIVALENCE (CBUF(1),CBR(1,1))
      REAL FFS(2,NP)
      EQUIVALENCE (CFFS(1),FFS(1,1))
c
      NS=ICUT2-ICUT1+1
      IF (ICDR.EQ.1) THEN
       TERM=0.
      ELSE
       TERM=PI/4E0
      END IF
      IFN=IFN+1
      DO 30 JD=1,IR
      CALL RWDBUF(LUTGRN)
      DO 4 JR=ICUT1,ICUT2
      DO 3 I=1,3
      IF (IOUT(I).EQ.0) GO TO 3
      CALL RDBUF(LUTGRN,CFILE,2*IR)
      CFF(JR,I)=CFILE(JD)
 3    CONTINUE
 4    CONTINUE
C
C
      IF (NFLAG) THEN
       CALL FLLNEG
       IC1=NWVNO-ICUT2+1
       IC2=ICUT2
      ELSE
       IC1=ICUT1
       IC2=ICUT2
      END IF
C
C
      IF (IC1.GT.1.OR.IC2.LT.NWVNO) THEN
       IPL1=NWVNO
       IPL2=0
       DO 6 I=1,3
       IF (IOUT(I).GT.0) THEN
        if (IC1.GT.1) CALL VCLR(CFF(1,I),1,2*(IC1-1))
        if (IC2.LT.NWVNO) CALL VCLR(CFF(IC2+1,I),1,2*(NWVNO-IC2))
        CALL CHERMIT(CFF(1,I),NWVNO,IC1,IC2,DLWVNO,
     1              WK0,IPL1,IPL2)
       END IF
 6     CONTINUE
      END IF
C
C
      WKM=WK0+(NWVNO-1)*DLWVNO
      DO 10 J=1,NPLOTS
      RANGEM=R1+(J-1)*DLRAN
      RK=RANGEM*WKM
      IF (INTTYP.EQ.2) THEN
C *** FULL BESSEL FUNCTION INTEGRATION
        DO 11 II=1,NWVNO
         WN=WK0+(II-1)*DLWVNO
         RKL=WN*RANGEM
         ARG(II)=WN*RINTPL(BF0,0E0,ONODRK,NRKMAX,RKL)
         FAC(II)=WN*RINTPL(BF1,0E0,ONODRK,NRKMAX,RKL)
 11     CONTINUE
        FCI=DLWVNO
      ELSE IF (RK.GT.1E-3.OR.ICDR.EQ.1) THEN
        RST=TERM-WK0*RANGEM
        RSTP=-DLWVNO*RANGEM
        CALL VRAMP(RST,RSTP,ARG,1,NWVNO)
        CALL CVEXP(ARG,1,CBUF,2,NWVNO)
        RST=EXP(OFFIMA*RANGEM)
        CALL VSMUL(CBUF,1,RST,CBUF,1,2*NWVNO)
        IF (ICDR.EQ.1) THEN
          FCI=FNI5
        ELSE
          FCI=FNI5/SQRT(RANGEM)
        END IF
      ELSE
        DO 18 I=1,NWVNO
        CBUF(I)=CSQRT(CMPLX(WK0+(I-1)*DLWVNO,OFFIMA))
 18     CONTINUE
        FCI=DLWVNO
      END IF
      ICNT=0
      DO 20 I=1,3
      IF (IOUT(I).EQ.0) GO TO 20
      IF (INTTYP.EQ.2) THEN
        CALL VCLR(CBUF,1,2*NWVNO)
        IF (I.EQ.3) THEN
          CALL VNEG(FAC,1,CBR(2,1),2,NWVNO)
        ELSE
          CALL VMOV(ARG,1,CBR(1,1),2,NWVNO)
        END IF
      END IF
      IF (NWVNO.EQ.1) THEN
        CFILE(J+ICNT*NPLOTS)=CFF(1,I)*CBUF(1)*FCI
      ELSE IF (INTTYP.EQ.1.AND.RK.GT.1E-3) THEN
        CFILE(J+ICNT*NPLOTS)=FILON(CFF(1,I),CBUF(1),ARG(1),
     &         NWVNO,FCI)
      ELSE IF (I.NE.3.OR.RK.GT.1E-3) THEN
        CALL CVMUL(CFF(1,I),2,CBUF(1),2,CFFS(1),2,NWVNO,1)
        CALL VTRAPZ(FFS(1,1),2,RR,0,NWVNO,FCI)
        CALL VTRAPZ(FFS(2,1),2,RI,0,NWVNO,FCI)
        CFILE(J+ICNT*NPLOTS)=CMPLX(RR,RI)
      ELSE
        CFILE(J+ICNT*NPLOTS)=CNUL
      END IF
      ICNT=ICNT+1
 20   CONTINUE
 10   CONTINUE
      CALL WRBUF(LUTTRF,CFILE,2*NOUT*NPLOTS)
 30   CONTINUE
      CALL CLSBUF(LUTGRN)
      RETURN
      END
      SUBROUTINE TIMSER(DOMEGA,TSHIFT,JR,JD,NX,LX,MX)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
      CALL CVFILL(CNUL,CFF,2,NP3)
      CALL RWDBUF(LUTTRF)
      DO 10 J=LX,MX
      DO 5 JJ=1,IR
      CALL RDBUF(LUTTRF,CFILE,2*NOUT*NPLOTS)
      IF (JJ.EQ.JD) THEN
        ICNT=0
        DO 4 I=1,3
        IF (IOUT(I).EQ.0) GO TO 4
        CFF(J,I)=CFILE(JR+ICNT*NPLOTS)
        ICNT=ICNT+1
  4     CONTINUE
      END IF
  5   CONTINUE
 10   FAC(J)=J-1
      CALL VMUL(FAC(LX),1,DOMEGA,0,ARG(LX),1,NUMFR)
      CALL VMUL(ARG(LX),1,TSHIFT,0,ARG(LX),1,NUMFR)
      CALL CVEXP(ARG(LX),1,CBUF(LX),2,NUMFR)
      CALL CVMUL(CBUF(LX),2,CFFS(LX),2,CBUF(LX),2,NUMFR,1)
      DO 20 I=1,3
      IF (IOUT(I).EQ.0) GO TO 20
      CALL CVMUL(CFF(LX,I),2,CBUF(LX),2,CFF(LX,I),2,NUMFR,1)
      CALL RFFT(CFF(1,I),NX,-1)
 20   CONTINUE
      IF (OMEGIM.NE.0E0) THEN
        RST=-OMEGIM*TSHIFT
        RSTP=-OMEGIM*2E0*PI/(NX*DOMEGA)
        CALL VRAMP(RST,RSTP,ARG,1,NX)
        CALL VEXP(ARG,1,FAC,1,NX)
        DO 30 I=1,3
         IF (IOUT(I).GT.0) THEN
          CALL VMUL(CFF(1,I),1,FAC,1,CFF(1,I),1,NX)
         END IF
 30     CONTINUE
      END IF
      RETURN
      END
      SUBROUTINE MODES(IFI,NMMAX,NK,K,VK)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
      REAL K(NMMAX),VK(NMMAX)
C
      CALL VCLR(K,1,2*NMMAX)
      CALL VCLR(VK,1,2*NMMAX)
      CALL CVMAGS(CFF(1,IFI),2,FAC(NWVNO),-1,NWVNO)
      ANK=1.2
      CALL PKVAL(FAC,VK,NWVNO,K,NMMAX,ANK,-1)
      NK=ANK
      DO 10 I=1,NK
 10   K(I)=NWVNO-K(I)+1
      RETURN
      END
      SUBROUTINE EXTMDS(IC1,IC2)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
C
      DO 20 I=1,3
      IF (IOUT(I).EQ.0) GO TO 20
      IF (IC1.GT.1) CALL CVFILL(CMPLX(0.,0.),CFF(1,I),2,IC1)
      IF (IC2.LT.NWVNO) CALL CVFILL(CNUL,CFF(IC2+1,I),2,NWVNO-IC2)
      IPLOT1=NWVNO
      IPLOT2=0
      IF (IC1.LE.2.AND.IC2.GE.NWVNO) GO TO 20
       CALL CHERMIT(CFF(1,I),NWVNO,IC1,IC2,DLWVNO,WK0,
     1            IPLOT1,IPLOT2)
 20   CONTINUE
      RETURN
      END
      SUBROUTINE IMPMOD(IFI,DLWVNL,DELFRQ,AKM,PHVEL,GRPVEL,NM,
     1                  DELTA,THETA,LTYP,FOCDEP)
      INCLUDE 'compar.f'
      INCLUDE 'comnla.f'
      INCLUDE 'comnp.f'

      DIMENSION AKM(1),PHVEL(1),GRPVEL(1)
      COMPLEX CIN
      COMPLEX CAK0

      EQUIVALENCE (CAK0,AK0)
      CAK0=CMPLX(1E0,OFFIMA)
C
C
      DF=DELFRQ/5.
      FSAVE=FREQ
      CSAVE=CSQ
      DSAVE=DSQ
C
C
      FREQ=FSAVE-DF
      DSQ=2*PI*FREQ
      CSQ=DSQ*DSQ
      CALL PINIT2
      CALL PHASES(LS,FREQ,V,DELTA,THETA,LTYP,FOCDEP)
      DO 10 I=1,NM/2
      AK0=AKM(2*I)+DLWVNL
      DS=DLWVNL
      DO 11 L=1,4
      RINOLD=0.
 5    IF (ICDR.EQ.0) THEN
      FCC=SQRT(AK0)
      ELSE
      FCC=1.
      END IF
      WVNO=CAK0
      CALL INITS
      CALL BUILD
      CALL SOLVE
      CALL KERNEL(CFILE,1)
      GOTO (6,7,8),IFI
 6    CIN=FCC*CFILE(1)
      GO TO 9
 7    CIN=FCC*CFILE(2)
      GO TO 9
 8    CIN=FCC*CFILE(3)
 9    RIN=CABS(CIN)
C     WRITE(48,*) FREQ,I,L,AK0,RIN
      IF (RIN.GE.RINOLD) GO TO 12
      AK0=AK0+DS
      PHVEL(I)=AK0
      AK0=AK0+DS
      DS=DS*.1
      RINOLD=0.
      GO TO 11
 12   RINOLD=RIN
      AK0=AK0-DS
      GO TO 5
 11   CONTINUE
 10   CONTINUE
C
C
      FREQ=FSAVE+DF
      DSQ=2*PI*FREQ
      CSQ=DSQ*DSQ
      CALL PINIT2
      CALL PHASES(LS,FREQ,V,DELTA,THETA,LTYP,FOCDEP)
      DO 20 I=1,NM/2
C     AK0=AKM(2*I)-DLWVNL
      AK0=PHVEL(I)
      DS=DLWVNL
      DO 21 L=1,4
      RINOLD=0.
 15    IF (ICDR.EQ.0) THEN
      FCC=SQRT(AK0)
      ELSE
      FCC=1.
      END IF
      WVNO=CAK0
      CALL INITS
      CALL BUILD
      CALL SOLVE
      CALL KERNEL(CFILE,1)
      GOTO (16,17,18),IFI
 16    CIN=FCC*CFILE(1)
      GO TO 19
 17    CIN=FCC*CFILE(2)
      GO TO 19
 18    CIN=FCC*CFILE(3)
 19    RIN=CABS(CIN)
C     WRITE(48,*) FREQ,I,L,AK0,RIN
      IF (RIN.GE.RINOLD) GO TO 22
      AK0=AK0-DS
      GRPVEL(I)=AK0
      AK0=AK0-DS
      DS=DS*.1
      RINOLD=0.
      GO TO 21
 22   RINOLD=RIN
      AK0=AK0+DS
      GO TO 15
 21   CONTINUE
      AK0=GRPVEL(I)
      IF ((AK0-PHVEL(I)).GT.1E-10) THEN
      GRPVEL(I)=4E0*PI*DF/(AK0-PHVEL(I))
      ELSE
      GRPVEL(I)=1E6
      END IF
      PHVEL(I)=4E0*PI*FSAVE/(AK0+PHVEL(I))
 20   CONTINUE
      FREQ=FSAVE
      DSQ=DSAVE
      CSQ=CSAVE
      RETURN
      END
      SUBROUTINE PLDISP(PHVEL,GRPVEL,NM,LX,MX,DELFRQ,
     1           XLEN,YLEN,XLEFT,XRIGHT,XINC,
     2           YDOWN,YUP,YINC,TITLE)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
      INCLUDE 'complo.f'
      DIMENSION PHVEL(1),GRPVEL(1),X(NP2)
      CHARACTER*80 TITLE
      CHARACTER*6 OPTION(2),OPT2
      EQUIVALENCE (X(1),CFFS(1))
      DATA OPTION /'FIPP  ',' DISP '/
      OPTION(1)=PROGNM
      PTIT='DISPERSION CURVES'
      NLAB=0
      XTXT='Frequency (Hz)$'
      YTXT='Velocity (m/s)$'
      XTYP='LIN'
      YTYP='LIN'
      XDIV=1
      YDIV=1
      IGRID=1
      NC=2*NM
C *** WRITE PLP FILE
      CALL PLPWRI(OPTION,PTIT,TITLE,NLAB,LAB,XLEN,YLEN,
     &                  IGRID,XLEFT,XRIGHT,XINC,XDIV,XTXT,XTYP,
     &                  YDOWN,YUP,YINC,YDIV,YTXT,YTYP,NC)

      DO 20 I=1,NM
       LF=MX-LX+1
       TMIN=(LX-1)*DELFRQ
       DT=DELFRQ
C *** READ PHASE VELOCITIES
       REWIND 22
       JK=0
       DO 1300 J=LX,MX                 
        JK=JK+1
        READ(22,*) FR,LNM
        CALL VCLR(PHVEL,1,NM)
        READ(22,*) (PHVEL(III),III=1,LNM)
        X(JK)=PHVEL(I)
 1300  CONTINUE   
       CALL PLTWRI(LF,TMIN,DT,0.,0.,X(1),1,X(1),1)
C *** READ GROUP VELOCITIES
       REWIND 23
       JK=0
       DO 1400 J=LX,MX                 
        JK=JK+1
        READ(23,*) FR,LNM
        CALL VCLR(GRPVEL,1,NM)
        READ(23,*) (GRPVEL(III),III=1,LNM)
        X(JK)=GRPVEL(I)
 1400  CONTINUE   
       CALL PLTWRI(LF,TMIN,DT,0.,0.,X(1),1,X(1),1)
 20   CONTINUE
      RETURN
      END
      SUBROUTINE PLPULS(LF0,LF,TMIN,DT,TITLE,INR,
     1      XLEN,YLEN,XLEFT,XRIGHT,XINC,RANGE,SD,RD,C0)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
      INCLUDE 'complo.f'
      DIMENSION X(NP2,3)
      EQUIVALENCE (X(1,1),CFF(1,1))
      CHARACTER*80 TITLE
      CHARACTER*6 OPTION(2),OPT2(4)
      DATA OPT2 /'RPULSE','SPULSE','WPULSE','UPULSE'/
      OPTION(1)=PROGNM
      OPTION(2)=OPT2(INR+1)
      I=MAX(1,INR)
C *** FIND MAX AMPLITUDE
      NN=LF-LF0+1
      CALL VMAX(X(LF0,I),1,YMAX,NN)
      CALL VMIN(X(LF0,I),1,YMIN,NN)
      YMAX=MAX(ABS(YMIN),ABS(YMAX))      
      CALL AUTOAX(0.,YMAX,YLO,YUP,YINC,YDIV,NYDIF)
      YLO=-YUP
      IF (INR.EQ.0) THEN
       PTIT='SOURCE PULSE'
      ELSE
       PTIT='RECEIVED SIGNAL'
      END IF
 811  FORMAT('SD:',F9.1,' m$')
 812  FORMAT('RD:',F9.1,' m$')
 813  FORMAT('Range:',F6.1,' km$')
      NLAB=3
      WRITE(LAB(1),813) RANGE
      WRITE(LAB(2),811) SD
      WRITE(LAB(3),812) RD
      IF (C0.GT.1E-10.AND.INR.NE.0) THEN
       WRITE(XTXT,830) C0*1E-3
 830   FORMAT('Reduced time t-r/',F5.3,' (secs.)$')
      ELSE
       XTXT='Time (seconds)$'
      END IF
      GOTO(901,902,903,904),INR+1
 901  WRITE(YTXT,911) NYDIF
 911  FORMAT('Pressure (10**',I3,' Pa)$')
      go to 905
 902  WRITE(YTXT,912) NYDIF
 912  FORMAT('Normal stress (10**',I3,' Pa)$')
      go to 905
 903  WRITE(YTXT,913) NYDIF
 913  FORMAT('Vert. particle vel. (10**',I3,' m/s)$')
      GO TO 905
 904  WRITE(YTXT,914) NYDIF
 914  FORMAT('Hor. particle vel. (10**',I3,' m/s)$')
 905  CONTINUE
      XTYP='LIN'
      YTYP='LIN'
      XDIV=1
      IGRID=0
      NC=1
C *** WRITE PLP FILE
      CALL PLPWRI(OPTION,PTIT,TITLE,NLAB,LAB,XLEN,YLEN,
     &                  IGRID,XLEFT,XRIGHT,XINC,XDIV,XTXT,XTYP,
     &                  YLO,YUP,YINC,YDIV,YTXT,YTYP,NC)
      CALL PLTWRI(NN,TMIN,DT,0.,0.,X(LF0,I),1,X(LF0,I),1)
      RETURN
      END
      SUBROUTINE PLSTACK(TITLE,INR,XLEN,YLEN,
     1    XLEFT,XRIGHT,XINC,YDOWN,YUP,YINC,
     2    NC,SD,RD,C0)
      INCLUDE 'compar.f'
      INCLUDE 'complo.f'
      CHARACTER*80 TITLE
      CHARACTER*6 OPTION(2),OPT2(4)
      DATA OPT2 /'RPSTCK','SPSTCK','WPSTCK','UPSTCK'/
      OPTION(1)=PROGNM
      OPTION(2)=OPT2(INR+1)
      I=MAX(1,INR)
      IF (INR.EQ.2) THEN
        PTIT='VERTICAL PARTICLE VELOCITY'
      ELSE IF (INR.EQ.3) THEN
        PTIT='HORIZONTAL PARTICLE VELOCITY'
      ELSE
        PTIT='NORMAL STRESS'
      END IF
 811  FORMAT('SD:',F9.1,' m$')
 812  FORMAT('RD:',F9.1,' m$')
      NLAB=2
      WRITE(LAB(1),811) SD
      WRITE(LAB(2),812) RD
      IF (C0.GT.1E-10) THEN
       WRITE(XTXT,830) C0*1E-3
 830   FORMAT('Reduced time t-r/',F5.3,' (secs.)$')
      ELSE
       XTXT='Time (seconds)$'
      END IF
      YTXT='Range (km)$'
      XTYP='LIN'
      YTYP='LIN'
      XDIV=1
      YDIV=1
      IGRID=0
C *** WRITE PLP FILE
      CALL PLPWRI(OPTION,PTIT,TITLE,NLAB,LAB,XLEN,YLEN,
     &            IGRID,XLEFT,XRIGHT,XINC,XDIV,XTXT,XTYP,
     &            YDOWN,YUP,YINC,YDIV,YTXT,YTYP,NC)
      RETURN
      END
      SUBROUTINE PLSTDEP(TITLE,INR,XLEN,YLEN,
     1    XLEFT,XRIGHT,XINC,YDOWN,YUP,YINC,
     2    NC,SD,RANGE,C0)
      INCLUDE 'compar.f'
      INCLUDE 'complo.f'
      CHARACTER*80 TITLE
      CHARACTER*6 OPTION(2),OPT2(4)
      DATA OPTION /'FIPP  ','      '/
      DATA OPT2 /'RPSTDP','SPSTDP','WPSTDP','UPSTDP'/
      OPTION(1)=PROGNM
      OPTION(2)=OPT2(INR+1)
      I=MAX(1,INR)
      IF (INR.EQ.2) THEN
        PTIT='VERTICAL PARTICLE VELOCITY'
      ELSE IF (INR.EQ.3) THEN
        PTIT='HORIZONTAL PARTICLE VELOCITY'
      ELSE
        PTIT='NORMAL STRESS'
      END IF
 811  FORMAT('SD:',F9.1,' m$')
 813  FORMAT('Range:',F6.1,' km$')
      NLAB=2
      WRITE(LAB(1),811) SD
      WRITE(LAB(2),813) RANGE
      IF (C0.GT.1E-10) THEN
       WRITE(XTXT,830) C0*1E-3
 830   FORMAT('Reduced time t-r/',F5.3,' (secs.)$')
      ELSE
       XTXT='Time (seconds)$'
      END IF
      YTXT='Depth (m)$'
      XTYP='LIN'
      YTYP='LIN'
      XDIV=1
      YDIV=1
      IGRID=0
C *** WRITE PLP FILE
      CALL PLPWRI(OPTION,PTIT,TITLE,NLAB,LAB,XLEN,YLEN,
     &            IGRID,XLEFT,XRIGHT,XINC,XDIV,XTXT,XTYP,
     &            YDOWN,YUP,YINC,YDIV,YTXT,YTYP,NC)
      RETURN
      END
      SUBROUTINE OUSTACK(LF0,LF,TMIN,DT,OFFSET,FACTOR,I)
      INCLUDE 'compar.f'
      INCLUDE 'comnp.f'
      DIMENSION X(NP2,3)
      equivalence (X(1,1),CFF(1,1))
      NN=LF-LF0+1
      CALL VSMUL(X(LF0,I),1,FACTOR,ARG,1,NN)
      TM=TMIN+(LF0-1)*DT
      CALL PLTWRI(NN,TM,DT,OFFSET,0.,ARG,1,ARG,1)
      RETURN
      END
      SUBROUTINE PLFRSP(FRQ1,DELFRQ,NFR,TITLE,XLEN,YLEN)     
      INCLUDE 'compar.f'
      INCLUDE 'comnla.f'
      INCLUDE 'comnp.f'
      INCLUDE 'complo.f'
      DIMENSION FFS(2,NP)    
      CHARACTER*80 TITLE
      CHARACTER*6 OPTION(2),OPT2(3)
      EQUIVALENCE (FFS(1,1),CFFS(1))
      DATA OPTION /'FIPP  ','FRSPEC'/       
C       
      OPTION(1)=PROGNM
      OPTION(2)='FRSPEC'
      CALL CVMAGS(CFFS,2,ARG,1,NFR)
      CALL VSQRT(ARG,1,ARG,1,NFR)
      CALL VMAX(ARG,1,YMAX,NFR)
C       
      IPLOT1=1        
      IPLOT2=NFR        
C       
C XAXIS DEFINITION        
C       
      XMAX=(FRQ1+(NFR-1)*DELFRQ)      
      XMIN=FRQ1       
      CALL AUTOAX(XMIN,XMAX,XLEFT,XRIGHT,XINC,XDIV,NXDIF)
C       
C  YAXIS DEFINITION       
C       
      YMIN=0.0   
      CALL AUTOAX(YMIN,YMAX,YLO,YUP,YINC,YDIV,NYDIF)
      PTIT='SOURCE SPECTRUM'
      NLAB=0
      IF (NXDIF.EQ.0) THEN
       WRITE(XTXT,819)
 819   FORMAT('Frequency (Hz)$')
      ELSE
       WRITE(XTXT,820) NXDIF
 820   FORMAT('Frequency (10**',I3,' Hz)$')
      END IF
      WRITE(YTXT,821) NYDIF
 821  FORMAT('Modulus (10**',I3,')$')
      XTYP='LIN'
      YTYP='LIN'
      IGRID=0
      NC=1
C *** WRITE PLP FILE
      CALL PLPWRI(OPTION,PTIT,TITLE,NLAB,LAB,XLEN,YLEN,
     &                  IGRID,XLEFT,XRIGHT,XINC,XDIV,XTXT,XTYP,
     &                  YLO,YUP,YINC,YDIV,YTXT,YTYP,NC)
      CALL PLTWRI(NN,XMIN,DELFRQ,0.,0.,ARG(1),1,ARG(1),1)
      RETURN     
      END        
