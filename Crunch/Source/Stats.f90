MODULE StatsSubs

   ! This module contains the routines needed to compute statistics.

IMPLICIT NONE

CONTAINS

!=======================================================================
   SUBROUTINE StatInit ( Fi )


      ! This routine initializes the statistics.


   USE                                DataMod
   USE                                ProgGen


      ! Argument declarations.

   INTEGER, INTENT(IN)             :: Fi


      ! Local declarations.

   INTEGER                         :: IC



      ! Initialize statistics.

   DO IC=1,TotCols

      DataMaxs(IC,Fi) = -Biggest
      DataMins(IC,Fi) = Biggest

      DataSums(IC) = 0.0d0
      NumCross(IC) = 0

   ENDDO ! IC


   RETURN
   END SUBROUTINE StatInit ! ( Fi )
!=======================================================================
   SUBROUTINE StatOpen ( Fi )


      ! This routine creates the statistics file.


   USE                                DataMod
   USE                                ProgGen


      ! Argument declarations.

   INTEGER, INTENT(IN)             :: Fi


      ! Local declarations.

   INTEGER                         :: Fil
   INTEGER                         :: IOS

   CHARACTER(300)                  :: Frmt
   CHARACTER(100)                  :: StatFile



      ! Get date and time for statistics file.

   DateStr = CurDate()
   TimeStr = CurTime()


      ! Create the name for the statistics file.

   IF ( Aggregate )  THEN
      Fil      = 1
      StatFile = TRIM( AggRoot )//'.sts'
   ELSE
      Fil      = Fi
      StatFile = TRIM( RootName(Fi) )//'.sts'
   ENDIF


      ! Open the statistics file.

   CALL GetNewUnit ( SU )
   OPEN ( SU , FILE=Trim( StatFile ) , STATUS='UNKNOWN' , FORM='FORMATTED' , IOSTAT=IOS )

   IF ( IOS /= 0 )  THEN
      CALL ProgAbort ( ' Warning.  The statistics file "'//Trim( StatFile )//'" could not be opened.')
   ENDIF


      ! Write the appropriate header for aggregate or individual statistics.

   Frmt = "( / 'Statistics generated by ' , A , A , ' on ' , A , ' at ' , A , '.' )"
   WRITE (SU,Frmt)  TRIM( ProgName ), TRIM( ProgVer ), DateStr, TimeStr

   IF ( Aggregate )  THEN
      IF ( BadFiles == 0 )  THEN
         Frmt = "( / 'These aggregate statistics were based upon ' , A , ' records from ' , A " &
              //" , ' input files.' )"
         WRITE (SU,Frmt)  TRIM( Int2LStr( AnalRecs ) ), TRIM( Int2LStr( GoodFiles ) )
      ELSE
         Frmt = "( / 'These aggregate statistics were based upon ' , A , ' records from ' , A " &
              //" , ' of the ' , A , ' specified input files.' )"
         WRITE (SU,Frmt)  TRIM( Int2LStr( AnalRecs ) ), TRIM( Int2LStr( GoodFiles ) ), TRIM( Int2LStr( NumFiles ) )
      ENDIF
   ELSE
      Frmt = "( / 'These statistics for ""' , A , '"" were based upon ' , A , ' records.' )"
      WRITE (SU,Frmt)  TRIM( FileName(Fi) ), TRIM( Int2LStr( AnalRecs ) )
   ENDIF

   IF ( Do_PF )  THEN
     WRITE (SU,'(A)')  'The peak-finding algorithm was used.'
   ELSE
     WRITE (SU,'(A)')  'The peak-finding algorithm was not used.'
   ENDIF


      ! Write out mean wind speed and turbulence intensity.

   IF ( WS_Col > 0 )  THEN

      IF ( TabDelim )  THEN
         IF ( HaveUnits )  THEN
            WRITE (SU,'(/,A,F5.1,1X,A,/,A,F5.1,A)')  'Mean wind speed =' , MeanWs(Fil) , Units(WS_Col) , &
                                                     'Turbulence intensity =' , TrbInt(Fil) , '%'
         ELSE
            WRITE (SU,'(/,A,F5.1,/,A,F5.1,A)')  'Mean wind speed =' , MeanWs(Fil) , &
                                                'Turbulence intensity =' , TrbInt(Fil) , '%'
         ENDIF
      ELSE
         IF ( HaveUnits )  THEN
            WRITE (SU,'(/,A,F5.1,1X,A,/,A,F5.1,A)')  'Mean wind speed      =' , MeanWs(Fil) , Units(WS_Col) , &
                                                     'Turbulence intensity =' , TrbInt(Fil) , '%'
         ELSE
            WRITE (SU,'(/,A,F5.1,/,A,F5.1,A)')  'Mean wind speed      =' , MeanWs(Fil) , &
                                                'Turbulence intensity =' , TrbInt(Fil) , '%'
         ENDIF
      ENDIF

   ENDIF

      ! Write the column headings.

   IF ( TabDelim )  THEN

      IF ( HaveUnits )  THEN
         Frmt = "( / 'Parameter"//Tab//"Units"//Tab//"Minimum"//Tab//"Mean"//Tab//"Maximum"//Tab//"MaxRange"//Tab//"StandDev"//Tab &
              //"Skewness"//Tab//"Kurtosis"//Tab//"MeanXFreq' )"
      ELSE
         Frmt = "( / 'Parameter"//Tab//"Minimum"//Tab//"Mean"//Tab//"Maximum"//Tab//"MaxRange"//Tab//"StandDev"//Tab &
              //"Skewness"//Tab//"Kurtosis"//Tab//"MeanXFreq' )"
      ENDIF

      WRITE (SU,Frmt)

   ELSE

      IF ( HaveUnits )  THEN
         Frmt = "(/,'Parameter  AA  Units',5X,8"//TextFmt//")"
         WRITE (SU,Frmt)  '   Minimum', '      Mean', '   Maximum', '  MaxRange' &
                        , '  StandDev', '  Skewness', '  Kurtosis', ' MeanXFreq'
         Frmt = "('---------  --  -----',5X,8"//TextFmt//")"
         WRITE (SU,Frmt)  '   -------', '      ----', '   -------', '  --------' &
                        , '  --------', '  --------', '  --------', ' ---------'
      ELSE
         Frmt = "(/,'Parameter  AA',8"//TextFmt//")"
         WRITE (SU,Frmt)  '   Minimum', '      Mean', '   Maximum', '  MaxRange' &
                        , '  StandDev', '  Skewness', '  Kurtosis', ' MeanXFreq'
         Frmt = "('---------  --',8"//TextFmt//")"
         WRITE (SU,Frmt)  '   -------', '      ----', '   -------', '  --------' &
                        , '  --------', '  --------', '  --------', ' ---------'
      ENDIF

   ENDIF


   RETURN
   END SUBROUTINE StatOpen ! ( Fi )
!=======================================================================
   SUBROUTINE StatOut ( Fi , IC )

      ! This routine writes the statistics.

   USE                                DataMod
   USE                                ProgGen


      ! Argument declarations.

   INTEGER, INTENT(IN)             :: Fi
   INTEGER, INTENT(IN)             :: IC


      ! Local declarations.

   CHARACTER( 3)                   :: AA
   CHARACTER(50)                   :: Frmt



      ! Set the AA field if appripriate.

   IF ( IC > NonAACols )  THEN

      IF ( IC > NonAACols+NumAACols )  THEN
         AA = '-aa'
      ELSE
         AA = ' aa'
      ENDIF
   ELSE
      AA = '   '
   ENDIF


      ! Write the statistics.

   IF ( TabDelim )  THEN

      IF ( HaveUnits )  THEN

         Frmt = "(2A,'"//Tab//"',A,8('"//Tab//"',"//RealFmt//"))"

         WRITE (SU,Frmt)  TRIM( Titles(IC) ), TRIM( AA ), TRIM( Units(IC) ), &
                          DataMins(IC,Fi), DataMeans(IC,Fi), DataMaxs(IC,Fi), DataMaxs(IC,Fi)-DataMins(IC,Fi), &
                          StdDev(IC,Fi), Skewness(IC,Fi), Kurtosis(IC,Fi), XFreq(IC,Fi)

      ELSE

         Frmt = "(2A,8('"//Tab//"',"//RealFmt//"))"

         WRITE (SU,Frmt)  TRIM( Titles(IC) ), TRIM( AA ), &
                          DataMins(IC,Fi), DataMeans(IC,Fi), DataMaxs(IC,Fi), DataMaxs(IC,Fi)-DataMins(IC,Fi), &
                          StdDev(IC,Fi), Skewness(IC,Fi), Kurtosis(IC,Fi), XFreq(IC,Fi)

      ENDIF

   ELSE

      IF ( HaveUnits )  THEN

         Frmt = "(2A,2X,A,8("//RealFmt//"))"

         WRITE (SU,Frmt)  Titles(IC), AA, Units(IC), &
                          DataMins(IC,Fi), DataMeans(IC,Fi), DataMaxs(IC,Fi), DataMaxs(IC,Fi)-DataMins(IC,Fi), &
                          StdDev(IC,Fi), Skewness(IC,Fi), Kurtosis(IC,Fi), XFreq(IC,Fi)

      ELSE

         Frmt = "(2A,8("//RealFmt//"))"

         WRITE (SU,Frmt)  Titles(IC), AA, &
                          DataMins(IC,Fi), DataMeans(IC,Fi), DataMaxs(IC,Fi), DataMaxs(IC,Fi)-DataMins(IC,Fi), &
                          StdDev(IC,Fi), Skewness(IC,Fi), Kurtosis(IC,Fi), XFreq(IC,Fi)

      ENDIF

   ENDIF


   RETURN
   END SUBROUTINE StatOut !  ( Fi , IC )
!=======================================================================
   SUBROUTINE Stats ( Fi )


      ! This routine generates and writes the statistics.


   USE                             CrunchIO
   USE                             DataMod
   USE                             ProgGen


      ! Argument declarations.

   INTEGER, INTENT(IN)             :: Fi


      ! Local declarations.

   REAL                         :: Delta
   REAL                         :: DelTime

   INTEGER                      :: Fil
   INTEGER                      :: IC
   INTEGER                      :: IR



         ! Tell them why we're here.

   CALL WrScr ( '  Computing statistics.' )


      ! Compute means.

   DO IC=1,TotCols

      DataMeans(IC,Fi) = DataSums(IC)/AnalRecs

   ENDDO ! IC


      ! Initialize sums for higher moments.

   DO IC=1,TotCols
      DataSum2(IC) = 0.0d0
      DataSum3(IC) = 0.0d0
      DataSum4(IC) = 0.0d0
   ENDDO ! IC


      ! Are we doing aggregates?  If so, process data for all files.

   IF ( Aggregate )  THEN


         ! Let's process all the data files.

      DO Fil=1,GoodFiles


            ! Read through entire time history to compute the higher moments and
            ! mean crossings for all files.

         DO IR=1,NumRecs


               ! Accumulate sum-squared error, etc. and mean crossings.

            DO IC=1,TotCols

               Delta = ConvData(IC,IR,Fil) - DataMeans(IC,1)

               DataSum2(IC) = DataSum2(IC) + Delta**2
               DataSum3(IC) = DataSum3(IC) + Delta**3
               DataSum4(IC) = DataSum4(IC) + Delta**4

               IF ( IR > 1 )  THEN

                  IF ( ( ConvData(IC,IR  ,Fil) >= DataMeans(IC,1) ) .AND. &
                       ( ConvData(IC,IR-1,Fil) <  DataMeans(IC,1) ) )  THEN

                     NumCross(IC) = NumCross(IC) + 1

                  ENDIF

               ENDIF

            ENDDO ! IC

         ENDDO ! IR

      ENDDO ! Fil


         ! Calculate delta time.

      DelTime = ConvData(TimeCol,2,1) - ConvData(TimeCol,1,1)


   ELSE


         ! Read through entire time history to compute the higher moments and
         ! mean crossings for this file.

      DO IR=1,NumRecs


            ! Accumulate sum-squared error, etc. and mean crossings.

         DO IC=1,TotCols

            Delta = ConvData(IC,IR,Fi) - DataMeans(IC,Fi)

            DataSum2(IC) = DataSum2(IC) + Delta**2
            DataSum3(IC) = DataSum3(IC) + Delta**3
            DataSum4(IC) = DataSum4(IC) + Delta**4

            IF ( IR > 1 )  THEN

               IF ( ( ConvData(IC,IR  ,Fi) >= DataMeans(IC,Fi) ) .AND. &
                    ( ConvData(IC,IR-1,Fi) <  DataMeans(IC,Fi) ) )  THEN

                  NumCross(IC) = NumCross(IC) + 1

               ENDIF

            ENDIF

         ENDDO ! IC

      ENDDO ! IR


         ! Calculate delta time.

      DelTime = ConvData(TimeCol,2,Fi) - ConvData(TimeCol,1,Fi)


   ENDIF


      ! If available, calculate the mean wind speed and turbulence intensity.

   IF ( WS_Col > 0 )  THEN

      IF ( Aggregate )  THEN

         MeanWS(1) = DataMeans(WS_Col,1)

         IF ( AnalRecs > 1 )  THEN
            TrbInt(1) = 100.0*SQRT( DataSum2(WS_Col)/( AnalRecs - 1 ) )/MeanWs(1)
         ELSE
            TrbInt(1) = 0.0
         ENDIF

      ELSE

         MeanWS(Fi) = DataMeans(WS_Col,Fi)

         IF ( AnalRecs > 1 )  THEN
            TrbInt(Fi) = 100.0*SQRT( DataSum2(WS_Col)/( AnalRecs - 1 ) )/MeanWs(Fi)
         ELSE
            TrbInt(Fi) = 0.0
         ENDIF

      ENDIF

   ENDIF


      ! Create the statistics file if requested.

   IF ( Out_Stats )  CALL StatOpen ( Fi )


      ! Generate statistics for the higher moments and crossing frequencies
      ! if we have more than one data point.  Otherwise, set them to zero.

   IF ( AnalRecs > 1 )  THEN

      DO IC=1,TotCols

         StdDev(IC,Fi) = SQRT( DataSum2(IC)/( AnalRecs - 1 ) )

         IF ( StdDev(IC,Fi) == 0.0 )  THEN
            Skewness(IC,Fi) = 0.0
            Kurtosis(IC,Fi) = 0.0
         ELSE
            Skewness(IC,Fi) = DataSum3(IC)/( AnalRecs*StdDev(IC,Fi)**3 )
            Kurtosis(IC,Fi) = DataSum4(IC)/( AnalRecs*StdDev(IC,Fi)**4 ) - 3.0
         ENDIF

         XFreq(IC,Fi) = NumCross(IC)/( DelTime*( AnalRecs - 1 ) )


            ! Output data if requested.

         IF ( Out_Stats )  CALL StatOut ( Fi , IC )

      ENDDO ! IC

   ELSE

      DO IC=1,TotCols

         StdDev  (IC,Fi) = 0.0
         Skewness(IC,Fi) = 0.0
         Kurtosis(IC,Fi) = 0.0
         XFreq   (IC,Fi) = 0.0


            ! Output data if requested.

         IF ( Out_Stats )  CALL StatOut ( Fi , IC )

      ENDDO ! IC

   ENDIF


      ! If all of the requested input files could not be read for aggregate analyses,
      ! append the list of bad files to the output.

   IF ( Aggregate .AND. ( BadFiles > 0 ) )  CALL WrBadList ( SU )


      ! Close statistics file.

   IF ( Out_Stats )  CLOSE ( SU )


   RETURN
   END SUBROUTINE Stats ! ( Fi )
!=======================================================================
   SUBROUTINE StatUpd ( IFi , Fi , IR )


      ! This routine generates statistics of the output data.


   USE                                DataMod


      ! Argument declarations.

   INTEGER, INTENT(IN)             :: Fi


      ! Local declarations.

   INTEGER                         :: IC
   INTEGER                         :: IFi
   INTEGER                         :: IR



      ! Update statistics.

   DO IC=1,TotCols

      DataSums(IC) = DataSums(IC) + ConvData(IC,IR,Fi)

      IF ( ConvData(IC,IR,Fi) .LT. DataMins(IC,IFi) )  DataMins(IC,IFi) = ConvData(IC,IR,Fi)
      IF ( ConvData(IC,IR,Fi) .GT. DataMaxs(IC,IFi) )  DataMaxs(IC,IFi) = ConvData(IC,IR,Fi)

   ENDDO


   RETURN
   END SUBROUTINE StatUpd ! ( IFi , Fi , IR )
!=======================================================================
   SUBROUTINE SumryOpen


      ! This routine open the summary files and (if appropriate) starts them
      ! with headers.


   USE                              DataMod
   USE                              ProgGen


      ! Local declarations.

   INTEGER                       :: IC
   INTEGER                       :: IOS
   INTEGER                       :: SF_Col
   INTEGER                       :: Unit

   CHARACTER(200)                :: FormStr
   CHARACTER( 17)                :: Titl



      ! Get date and time for summary files.

   DateStr = CurDate()
   TimeStr = CurTime()


      ! Open each of the summary files.

   DO IC=1,NumSFCols

      Unit = IC + 20

      SF_Col = SF_Cols(IC)

      IF ( SF_Col > NonAACols )  THEN
         IF ( SF_Col > NonAACols+NumAACols )  THEN
            Titl = TRIM( Titles(SF_Col) )//'-aa.sum'
         ELSE
            Titl = TRIM( Titles(SF_Col) )//'_aa.sum'
         ENDIF
      ELSE
         Titl = TRIM( Titles(SF_Col) )//'.sum'
      ENDIF

      OPEN ( Unit, FILE=TRIM( Titl ), STATUS='UNKNOWN', FORM='FORMATTED', IOSTAT=IOS )

      IF ( IOS /= 0 )  THEN
         CALL ProgAbort ( ' Warning.  The summary file "'//Trim( Titl )//'" could not be opened.')
      END IF


         ! Create the header.

      IF ( HaveUnits )  THEN
         FormStr = "( / 'These statistics for ""' , 2A , '"" were generated by ' , A , A , ' on ' , A , ' at ' , A , '.' )"
         WRITE (Unit,FormStr)   TRIM( Titles(SF_Col) ), TRIM( Units(SF_Col) ), TRIM( ProgName ), TRIM( ProgVer ), DateStr, TimeStr
      ELSE
         FormStr = "( / 'These statistics for ""' , A , '"" were generated by ' , A , A , ' on ' , A , ' at ' , A , '.' )"
         WRITE (Unit,FormStr)   TRIM( Titles(SF_Col) ), TRIM( ProgName ), TRIM( ProgVer ), DateStr, TimeStr
      ENDIF

      IF ( Do_PF )  THEN
        WRITE (Unit,'(A)')  'The peak-finding algorithm was used.'
      ELSE
        WRITE (Unit,'(A)')  'The peak-finding algorithm was not used.'
      ENDIF


         ! Write the column headings.

      IF ( TabDelim )  THEN

         IF ( WS_Col > 0 )  THEN
            FormStr = "( / 'Data File"//Tab//"MeanWS"//Tab//"TurbInt"//Tab//"Minimum"//Tab//"Mean"//Tab//"Maximum"//Tab &
                    //"MaxRange"//Tab//"StandDev"//Tab//"Skewness"//""//Tab//"Kurtosis"//Tab//"MeanXFreq' )"
         ELSE
            FormStr = "( / 'Data File"//Tab//"Minimum"//Tab//"Mean"//Tab//"Maximum"//Tab//"MaxRange"//Tab//"StandDev"//Tab &
                    //"Skewness"//Tab//"Kurtosis"//""//Tab//"MeanXFreq' )"
         ENDIF

         WRITE (Unit,FormStr)

      ELSE

         IF ( WS_Col > 0 )  THEN

            FormStr = "(/,'Data File',   X,'   MeanWS    TurbInt',8"//TextFmt//")"
            WRITE (FormStr(16:18),'(I3)')  MaxNLen - 7
            WRITE (Unit,FormStr)  '   Minimum', '      Mean', '   Maximum', '  MaxRange', '  StandDev', '  Skewness', &
                                  '  Kurtosis', ' MeanXFreq'

            FormStr = "( '---------',   X,'   ------    -------',8"//TextFmt//")"
            WRITE (FormStr(15:17),'(I3)')  MaxNLen - 7
            WRITE (Unit,FormStr)  '   -------', '      ----', '   -------', '  --------', '  --------', '  --------', &
                                  '  --------', ' ---------'

         ELSE

            FormStr = "(/,'Data File',   X,8"//TextFmt//")"
            WRITE (FormStr(16:18),'(I3)')  MaxNLen - 7
            WRITE (Unit,FormStr)  '   Minimum', '      Mean', '   Maximum', '  MaxRange', '  StandDev', '  Skewness', &
                                  '  Kurtosis', ' MeanXFreq'

            FormStr = "(  '---------',   X,8"//TextFmt//")"
            WRITE (FormStr(15:17),'(I3)')  MaxNLen - 7
            WRITE (Unit,FormStr)  '   -------', '      ----', '   -------', '  --------', '  --------', '  --------', &
                                  '  --------', ' ---------'

         ENDIF

      ENDIF

   ENDDO ! IC


   RETURN
   END SUBROUTINE SumryOpen
!=======================================================================
   SUBROUTINE SumryUpd ( Fi )


      ! This routine updates the summary files with this file's statistics.


   USE                                DataMod
   USE                                ProgGen


      ! Argument declarations.

   INTEGER, INTENT(IN)             :: Fi


      ! Local declarations.

   INTEGER                         :: Col
   INTEGER                         :: IC

   CHARACTER(50)                   :: Frmt



      !  Use the appropriate format statement.

   IF ( TabDelim )  THEN
      Frmt = "( A , 10( '"//Tab//"' , "//RealFmt//" ) )"
   ELSE
      Frmt = "( A , 10( "//RealFmt//" ) )"
   ENDIF


      ! Loop through all the summary files.

   DO IC=1,NumSFCols

      Col = SF_Cols(IC)

      IF ( WS_Col > 0 )  THEN
         WRITE (IC+20,Frmt)  Filename(Fi)(1:MaxNLen), MeanWS(Fi), TrbInt(Fi), &
                             DataMins(Col,Fi), DataMeans(Col,Fi), DataMaxs(Col,Fi), &
                             DataMaxs(Col,Fi)-DataMins(Col,Fi), &
                             StdDev(Col,Fi), Skewness(Col,Fi), Kurtosis(Col,Fi), XFreq(Col,Fi)
      ELSE
         WRITE (IC+20,Frmt)  Filename(Fi)(1:MaxNLen), &
                             DataMins(Col,Fi), DataMeans(Col,Fi), DataMaxs(Col,Fi), &
                             DataMaxs(Col,Fi)-DataMins(Col,Fi), &
                             StdDev(Col,Fi), Skewness(Col,Fi), Kurtosis(Col,Fi), XFreq(Col,Fi)
      ENDIF

   ENDDO  ! IC


   RETURN
   END SUBROUTINE SumryUpd ! ( Fi )
!=======================================================================

END MODULE StatsSubs
