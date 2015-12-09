c: *******************************
c: *   AUTHOR (1996):            *
c: *         E M G  GROUP        *
c: *     S A C L A N T C E N     *
c: *******************************
      subroutine rx_mode_field(jfhi,jflo,nsctr,intrpl,knbb,
     .                         phi_bx,nrec,nrecusr)
c
c: Computes field given mode eigenvalues and mode function values.
c
      implicit none
      include 'Parms_com'
      common /svp_com1/
     . nsvp,nlayb,nlayt,svp_ver,
     . rend,rstart
      integer*4 nsvp,nlayb,nlayt
      real*4 svp_ver, twopie
      real*8 rend,rstart
      common /ny_com/ narray(NVRMAX),act_sect
      integer*4 narray,act_sect
      common /out_b/
     .   sq2pir(RGMAX,NSRMAX),range(RGMAX),rho_sr(NVRMAX),
     .   dtiltp(NSRMAX)
      real*8 range,rho_sr,dtiltp
      complex*8 sq2pir
      include 'i_o_1tf_com'
      include 'i_o_2_com'
      include 'freq_com'
      include 'freq2_com'
      include 'deltaf_com'

      integer*4 rindex1,rindex2,rxs,nsctr
      integer*4 jfhi,jflo,kf,intrpl(RGMAX)
      integer*4 jm,msrc,nrec,nrecusr
      integer*4 j,ik,jj,jk,jkl,modupd,jdf,idum1,idum2
      integer*4 displ,displ_old
      real*4 phi_bx(NVRMAX,NM_MAX,NFCMAX)
      real*4 alpha1,phintusr(NSRMAX)
      real*8 d_range,sqr_rngint
      real*8 sqr_range,dr_range,d_rangei
      complex*16 knbb(NM_MAX,NFCMAX)
      complex*16 alphak,betak,dc_zero
      complex*16 knx1,knx,iknx,sqkn,cfac2,exp_sqk
      data dc_zero /(0.d0,0.d0)/
      data twopie/6.28318530717959/
c
      if(jflo .eq. 1) ishft=0

      nmodemin=min0(nmodemin,nmode)
c
      if(nsctr.eq.1) then

cc!         msrc=mzsrc(1)
         msrc=nrecusr+1

         if(NSCTOR .eq. 1) then
            do kf=jflo+ishft,jfhi
               jdf = kf-jflo+1
               modupd = min(mod_updt(jdf),nmodemin)
               do jm=1,modupd
                  sqkn=cdsqrt(knbb(jm,jdf))
                  phisrc(jm,jdf)=phi_bx(msrc,jm,jdf)/
     .                 rho_sr(msrc)
                  do rxs=1,nrng
                     jj=(rxs-1)*nfbb*nrec
                     do jk = 1,nrec
                        iknx=dcmplx(-dimag(knbb(jm,jdf)),
     .                       dreal(knbb(jm,jdf)))*(range(rxs)+
     .                       dtiltp(jk))
                        if(sqkn .eq. 0.0) then
                           exp_sqk=dc_zero
                        else
                           exp_sqk=cdexp(iknx)/sqkn
                        endif
                        cfac2 = sq2pir(rxs,jk)*phisrc(jm,jdf)*exp_sqk
                        jkl = jk
                        tf(kf+jj)=tf(kf+jj)+cfac2*
     .                       phi_bx(jkl,jm,jdf)
                        jj=jj+nfbb
                     enddo
                  enddo
               enddo
            enddo

         else
            
            do kf=jflo+ishft,jfhi
               jdf = kf-jflo+1
               modupd = min(mod_updt(jdf),nmodemin)
               do jm=1,modupd
c     : Initialize complex integral of k:
                  kintg(jm,jdf)=dc_zero
c     : rho is included in mode_fun:
                  displ=0
                  do jj=1,narray(1)
                   do j=1,nrecusr
cc!                     jkl = mzrec(j+displ)
                     jkl = j+displ
                     phiold(j+displ,jm,jdf)=phi_bx(jkl,jm,jdf)
                   enddo
                   displ=displ+nrecusr+1
                  enddo
                  phisrc(jm,jdf)=phi_bx(msrc,jm,jdf)/
     .                    rho_sr(msrc)
                  knold(jm,jdf)=knbb(jm,jdf)
               enddo
            enddo
          
         endif
c     elseif(nsctr .ne. nsctor) then
      else
         d_range = rend-rstart
         sqr_rngint = d_range*d_range
         d_rangei = 1.d0/d_range
         rindex2=intrpl(nsctr-1)
         if (nsctr .eq. 2) then
            rindex1 = 1
         else
            if (intrpl(nsctr-2) .eq. 0) then
               rindex1 = 1
            else
               rindex1=intrpl(nsctr-2)+1
            endif
         endif
         
         do kf=jflo+ishft,jfhi
            jdf = kf-jflo+1
            modupd = min(mod_updt(jdf),nmodemin)
            do jm=1,modupd
               displ=0
               alphak = knbb(jm,jdf)-knold(jm,jdf)
               alphak = alphak*d_rangei
               betak = knold(jm,jdf)
               
               if(intrpl(nsctr-1) .ne. 0) then
                  
                  do rxs=rindex1,rindex2
                     jj=(rxs-1)*nfbb*nrecusr
                     do j = 1,nrecusr
                        dr_range = range(rxs) + dtiltp(j) - rstart
                        sqr_range = dr_range*dr_range
                        knx = alphak*dr_range+betak
                        knx1 = .5d0*alphak*sqr_range +
     .                       betak*dr_range+kintg(jm,jdf)
                        iknx=dcmplx(-dimag(knx1),dreal(knx1))
                        sqkn=cdsqrt(knx)
                        if(sqkn .eq. 0.0) then
                           exp_sqk=dc_zero
                        else
                           exp_sqk=cdexp(iknx)/sqkn
                        endif
                        jkl = j+displ
                        alpha1=phi_bx(jkl,jm,jdf)-
     .                       phiold(j+displ,jm,jdf)
                        alpha1=alpha1*d_rangei
                        phintusr(j) = alpha1*dr_range+
     .                       phiold(j+displ,jm,jdf)
c                        write(99,'(2I,10E15.5)')
c     .                       j,displ,range(rxs),alpha1,
c     .                       phiold(j+displ,jm,jdf),
c     .                       phi_bx(jkl,jm,jdf),
c     .                       phintusr(j),d_rangei,dr_range
                        cfac2 = sq2pir(rxs,jkl)*phisrc(jm,jdf)*exp_sqk
                        tf(kf+jj)=tf(kf+jj)+cfac2*phintusr(j)
                        jj=jj+nfbb
                     enddo
                     displ=displ+nrecusr+1
                  enddo
               endif
               
               kintg(jm,jdf)=kintg(jm,jdf)+
     .              0.5d0*alphak*sqr_rngint+betak*d_range
            enddo
         enddo
         
         if (nsctr .ne. nsctor) then
            
            do kf=jflo+ishft,jfhi
               jdf = kf-jflo+1
               modupd = min(mod_updt(jdf),nmodemin)
               do j=1,modupd
                  knold(j,jdf)=knbb(j,jdf)
                  if((intrpl(nsctr+1) .ne. 0) .or.
     .                 (intrpl(nsctr) .ne. 0)) then
c                     ncount=narray(nsctr+1)
c                     if(narray(nsctr+1) .eq.0) ncount=1
c                     do jd=1,ncount
                      do jj=displ+1,nrec
c                        jkl = mzrec(jj+displ)
                        jkl=jj
                        phiold(jj-displ,j,jdf)=phi_bx(jkl,j,jdf)
                      enddo
c                      displ=displ+nrecusr
c                     enddo
                  endif
               enddo
            enddo
         else
c     elseif(nsctr .eq. nsctor) then
            
            displ_old=displ
            do kf=jflo+ishft,jfhi
               jdf = kf-jflo+1
               modupd = min(mod_updt(jdf),nmodemin)
               do jm=1,modupd
                  sqkn=cdsqrt(knbb(jm,jdf))
                  displ=displ_old
                  do rxs=rindex2+1,nrng
                     jj=(rxs-1)*nfbb*nrecusr
                     do jk = 1,nrecusr
                        dr_range = range(rxs) + dtiltp(jk) - rend
                        knx1=knbb(jm,jdf)*dr_range+kintg(jm,jdf)
                        iknx=dcmplx(-dimag(knx1),dreal(knx1))
                        if(sqkn .eq. 0.0) then
                           exp_sqk=dc_zero
                        else
                           exp_sqk=cdexp(iknx)/sqkn
                        endif
                        cfac2 = sq2pir(rxs,jk)*phisrc(jm,jdf)*exp_sqk
                        jkl = jk+displ
                        tf(kf+jj)=tf(kf+jj)+cfac2*phi_bx(jkl,jm,jdf)
                        jj=jj+nfbb
                     enddo
                     displ=displ+nrecusr+1
                  enddo
               enddo
            enddo
            
         end if
      end if
      nmode=nmodemin
      
      do ik=1,NFCMAX
         mod_updt(ik) = 0
      enddo
      
      return
      end
