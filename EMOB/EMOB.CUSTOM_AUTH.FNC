CREATE OR REPLACE FUNCTION EMOB.custom_auth (p_username   IN VARCHAR2,
                                             p_password   IN VARCHAR2)
   RETURN BOOLEAN
IS
   vCheckStatus         VARCHAR2 (1);
   vUserSts             VARCHAR2 (1);
   vUserType            VARCHAR2 (3);
   vPwdDate             DATE;
   vUserPwd             VARCHAR2 (200);
   vInvLoginCnt         NUMBER := 0;
   vRestrictFromDt      DATE;
   vRestrictToDt        DATE;
   vOutPassword         VARCHAR2 (200);
   vMaxInvLoginAllow    NUMBER := 0;
   vSessionId           VARCHAR2 (100) := v ('APP_SESSION');
   vUserID              NUMBER;
   vLogonPassChange     VARCHAR2 (1);
   vSysdate             DATE := TO_DATE (SYSDATE, 'DD/MM/RRRR');
   vtodays              NUMBER (3);
   vFingerPrint         VARCHAR2 (1);
   vCount               NUMBER := 0;
   out_migflg           VARCHAR2 (1);
   vLogID               NUMBER;
   vErrCode             VARCHAR2 (3);
   vErrorMessage        VARCHAR2 (1024);
   vErrorMessage2       VARCHAR2 (1024);
   vErrorMessageMail    VARCHAR2 (1024);
   vErrorFlag           VARCHAR2 (2);
   vErrorFlag2          VARCHAR2 (1);
   vMessage             VARCHAR2 (3000);
   vCodeDesc            VARCHAR2 (1024);
   vUserMailId          VARCHAR2 (60);
   vMaxInvLogMailSend   NUMBER;
   vIp                  VARCHAR2 (1024) := NULL;
   vMacAddress          VARCHAR2 (1024) := NULL;
   vHarDiskSl           VARCHAR2 (1024) := NULL;
   vUuId                VARCHAR2 (1024) := NULL;
   vOsUser              VARCHAR2 (1024) := NULL;
   vBioMetricDeviceId   VARCHAR2 (1024) := NULL;
   vMyException         EXCEPTION;
BEGIN
   BEGIN
      SELECT CHECK_STATUS,
             USER_STS,
             USER_ID,
             USER_TYPE,
             PWD_DATE,
             USER_PWD,
             INV_LOGIN_CNT,
             RESTRICT_FROM_DT,
             RESTRICT_TO_DT,
             FINGER_PRINT,
             LOGON_PASS_CHANGE,
             TRIM (EMAIL_ID)
        INTO vCheckStatus,
             vUserSts,
             vUserID,
             vUserType,
             vPwdDate,
             vUserPwd,
             vInvLoginCnt,
             vRestrictFromDt,
             vRestrictToDt,
             vFingerPrint,
             vLogonPassChange,
             vUserMailId
        FROM emob.MB_USER_MST
       WHERE UPPER (USER_CODE) = UPPER (p_username);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         vErrCode := 'IUS';
         vErrorMessage := 'Invalid User.';
         RAISE vMyException;
      WHEN TOO_MANY_ROWS
      THEN
         vErrCode := 'IUS';
         vErrorMessage := 'Multiple User Found With Same User ID.';
         RAISE vMyException;
      WHEN OTHERS
      THEN
         vErrCode := 'IUS';
         vErrorMessage := 'Invalid User. - ' || SQLERRM;
         RAISE vMyException;
   END;

   BEGIN
      SELECT MAX_INV_LOGIN, MAX_INV_MAIL_SEND
        INTO vMaxInvLoginAllow, vMaxInvLogMailSend
        FROM emob.mb_global_rule;
   EXCEPTION
      WHEN OTHERS
      THEN
         vErrCode := 'OTH';
         vErrorMessage := 'Global Setup Error. - ' || SQLERRM;
         RAISE vMyException;
   END;

   IF vCheckStatus = 'N'
   THEN
      vErrCode := 'WFA';
      vErrorMessage :=
         'Your User ID is Waiting for Approval. Please Conatct With Administrator.';
      RAISE vMyException;
   END IF;

   IF vUserSts = 'E'
   THEN
      vErrCode := 'UEX';
      vErrorMessage := 'User is Expired.';
      RAISE vMyException;
   END IF;

   IF vUserSts = 'S'
   THEN
      vErrCode := 'USP';
      vErrorMessage := 'User is Suspend.';
      RAISE vMyException;
   END IF;

   IF vUserSts = 'T'
   THEN
      vErrCode := 'UTR';
      vErrorMessage := 'User is Terminated.';
      RAISE vMyException;
   END IF;

   IF TRUNC (SYSDATE) BETWEEN vRestrictFromDt AND vRestrictToDt
   THEN
      vErrCode := 'LRS';
      vErrorMessage := 'Today is Restricted for Your Login.';
      RAISE vMyException;
   END IF;



   IF vCheckStatus = 'A' AND vUserSts = 'A'
   THEN
      IF NVL (vInvLoginCnt, 0) > vMaxInvLoginAllow
      THEN
         BEGIN
            UPDATE emob.MB_USER_MST
               SET USER_STS = 'E'
             WHERE UPPER (USER_CODE) = UPPER (p_username);
         EXCEPTION
            WHEN OTHERS
            THEN
               vErrCode := 'OTH';
               vErrorMessage := 'Update Error. - ' || SQLERRM;
               RAISE vMyException;
         END;

         IF SQL%ROWCOUNT = 1
         THEN
            COMMIT;
         END IF;

         vErrCode := 'ITM';
         vErrorMessage :=
            'Login Denied, Exceeded the Max. No. of Invalid Try.';
         RAISE vMyException;
      END IF;

      --Must Be Open User Device Security
      /*BEGIN
         SELECT IP,
                MAC_ADDRESS,
                HARD_DISK_SL,
                UUID,
                OS_USER
           INTO vIp,
                vMacAddress,
                vHarDiskSl,
                vUuId,
                vOsUser
           FROM EMOB.USER_LOGIN_SYSTEM_INFO
          WHERE USER_ID = UPPER (p_username)
                AND SESSION_ID = v ('APP_SESSION');
      EXCEPTION
         WHEN OTHERS
         THEN
            vIp := NULL;
            vMacAddress := NULL;
            vHarDiskSl := NULL;
            vUuId := NULL;
            vOsUser := NULL;
      END;

      BEGIN
         SELECT DEVICE_ID
           INTO vBioMetricDeviceId
           FROM EMOB.FP_USER_LOGIN
          WHERE     USER_ID = vUserID
                AND SESSION_ID = v ('APP_SESSION')
                AND LOGIN_STATUS = 'N';
      EXCEPTION
         WHEN OTHERS
         THEN
            vBioMetricDeviceId := NULL;
      END;


      BEGIN
         emob.dpk_emob_security.
          prc_login_device_security (
            pUserId              => vUserID,
            pUserType            => vUserType,
            pBioMetricDeviceId   => vBioMetricDeviceId,
            pUuid                => vUuId,
            pHardDiskSlNo        => vHarDiskSl,
            pMacAddress          => vMacAddress,
            pOsUser              => vOsUser,
            pIp                  => vIp,
            pErrorFlag           => vErrorFlag,
            pErrorMessage        => vErrorMessage);
      EXCEPTION
         WHEN OTHERS
         THEN
            vErrCode := 'OTH';
            vErrorMessage :=
               'Device Security Process Calling Problem. - ' || SQLERRM;
            RAISE vMyException;
      END;

      IF vErrorFlag = 'Y'
      THEN
         BEGIN
            UPDATE emob.MB_USER_MST
               SET INV_LOGIN_CNT = NVL (INV_LOGIN_CNT, 0) + 1
             WHERE UPPER (USER_CODE) = UPPER (p_username);
         EXCEPTION
            WHEN OTHERS
            THEN
               vErrCode := 'OTH';
               vErrorMessage :=
                  'Invalid Login Update Error For Device Security. - '
                  || SQLERRM;
               RAISE vMyException;
         END;

         IF SQL%ROWCOUNT = 1
         THEN
            COMMIT;
         ELSE
            vErrCode := 'OTH';
            vErrorMessage :=
               'Problem Occur. Contact With Administrator For Device Security. - '
               || SQLERRM;
            RAISE vMyException;
         END IF;

         vInvLoginCnt := NVL (vInvLoginCnt, 0) + 1;
         vErrCode := 'OTH';
         RAISE vMyException;
      END IF;*/

      IF vFingerPrint = 'N'
      THEN
         IF p_password IS NULL
         THEN
            vErrCode := 'PNL';
            vErrorMessage := 'Invalid Password. Please Enter Your Password.';
            RAISE vMyException;
         END IF;

         BEGIN
            SELECT emob.
                    dfn_create_password_encrypted (p_username || vUserID,
                                                   p_password)
              INTO vOutPassword
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               vErrCode := 'OTH';
               vErrorMessage := 'Authorization Check Error. - ' || SQLERRM;
               RAISE vMyException;
         END;

         IF NVL (vOutPassword, 'x') <> NVL (vUserPwd, 'y')
         THEN
            BEGIN
               UPDATE emob.MB_USER_MST
                  SET INV_LOGIN_CNT = NVL (INV_LOGIN_CNT, 0) + 1
                WHERE UPPER (USER_CODE) = UPPER (p_username);
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrCode := 'OTH';
                  vErrorMessage := 'Update Error. - ' || SQLERRM;
                  RAISE vMyException;
            END;

            IF SQL%ROWCOUNT = 1
            THEN
               COMMIT;
            ELSE
               vErrCode := 'OTH';
               vErrorMessage :=
                  'Problem Occur. Contact With Administrator. - ' || SQLERRM;
               RAISE vMyException;
            END IF;


            vInvLoginCnt := NVL (vInvLoginCnt, 0) + 1;

            vErrCode := 'IPW';
            vErrorMessage := 'Incorrect Password.';
            RAISE vMyException;

            RETURN FALSE;
         ELSE
            BEGIN
               UPDATE emob.MB_USER_MST
                  SET LAST_LOGIN = SYSDATE,
                      LOGIN_CNT = NVL (LOGIN_CNT, 0) + 1
                WHERE UPPER (USER_CODE) = UPPER (p_username);
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrCode := 'OTH';
                  vErrorMessage := 'Update Error. - ' || SQLERRM;
                  RAISE vMyException;
            END;

            IF SQL%ROWCOUNT = 1
            THEN
               COMMIT;
            ELSE
               vErrCode := 'OTH';
               vErrorMessage :=
                  'Problem Found for Update Last Login & Login Count. Contact With Administrator.'
                  || SQLERRM;
               RAISE vMyException;
            END IF;

            BEGIN
               UPDATE emob.MB_USER_MST
                  SET inv_login_cnt = 0
                WHERE UPPER (USER_CODE) = UPPER (p_username);
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrCode := 'OTH';
                  vErrorMessage := 'Update Error Invalid Free. - ' || SQLERRM;
                  RAISE vMyException;
            END;

            RETURN TRUE;
         END IF;
      ELSIF vFingerPrint = 'Y'
      THEN
         IF p_password IS NULL
         THEN
            vErrCode := 'PNL';
            vErrorMessage := 'Invalid Password. Please Enter Your Password.';
            RAISE vMyException;
         END IF;

         BEGIN
            SELECT emob.
                    dfn_create_password_encrypted (p_username || vUserID,
                                                   p_password)
              INTO vOutPassword
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               vErrCode := 'OTH';
               vErrorMessage := 'Authorization Check Error. - ' || SQLERRM;
               RAISE vMyException;
         END;

         IF NVL (vOutPassword, 'x') <> NVL (vUserPwd, 'y')
         THEN
            BEGIN
               UPDATE emob.MB_USER_MST
                  SET INV_LOGIN_CNT = NVL (INV_LOGIN_CNT, 0) + 1
                WHERE UPPER (USER_CODE) = UPPER (p_username);
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrCode := 'OTH';
                  vErrorMessage := 'Update Error. - ' || SQLERRM;
                  RAISE vMyException;
            END;

            IF SQL%ROWCOUNT = 1
            THEN
               COMMIT;
            ELSE
               vErrCode := 'OTH';
               vErrorMessage :=
                  'Problem Found for Update Invalid Login Count. Contact With Administrator. - '
                  || SQLERRM;
               RAISE vMyException;
            END IF;

            vInvLoginCnt := NVL (vInvLoginCnt, 0) + 1;


            vErrCode := 'IPW';
            vErrorMessage := 'Incorrect Password.';
            RAISE vMyException;

            RETURN FALSE;
         ELSE
            BEGIN
               UPDATE emob.MB_USER_MST
                  SET LAST_LOGIN = SYSDATE,
                      LOGIN_CNT = NVL (LOGIN_CNT, 0) + 1
                WHERE UPPER (USER_CODE) = UPPER (p_username);
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrCode := 'OTH';
                  vErrorMessage := 'Login Update Error. - ' || SQLERRM;
                  RAISE vMyException;
            END;

            IF SQL%ROWCOUNT = 1
            THEN
               COMMIT;
            ELSE
               vErrCode := 'OTH';
               vErrorMessage :=
                  'Problem Found. Contact With Administrator. - ' || SQLERRM;
               RAISE vMyException;
            END IF;
         END IF;

         BEGIN
            SELECT COUNT (FINGER_STATUS)
              INTO vCount
              FROM emob.FP_USER_LOGIN
             WHERE     UPPER (USER_CODE) = UPPER (p_username)
                   AND SESSION_ID = vSessionId
                   AND LOGIN_STATUS = 'N';
         EXCEPTION
            WHEN OTHERS
            THEN
               vErrCode := 'OTH';
               vErrorMessage := 'Finger Error. - ' || SQLERRM;
               RAISE vMyException;
         END;

         IF vCount > 1
         THEN
            BEGIN
               UPDATE emob.FP_USER_LOGIN
                  SET LOGIN_STATUS = 'E'
                WHERE     UPPER (USER_CODE) = UPPER (p_username)
                      AND SESSION_ID = vSessionId
                      AND LOGIN_STATUS = 'N'
                      AND TRUNC (CREATE_DATE) = TRUNC (SYSDATE);
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrCode := 'OTH';
                  vErrorMessage := 'Finger Update Error. - ' || SQLERRM;
                  RAISE vMyException;
            END;

            COMMIT;

            vErrCode := 'IFN';
            vErrorMessage := 'Multiple Finger Print Found For Same Session.';
            RAISE vMyException;
         ELSIF vCount = 0
         THEN
            vErrCode := 'IFN';
            vErrorMessage := 'Finger Print Not Match.';
            /*'Finger Print Not Setup Yet For User ID: '
            || UPPER (p_username);*/
            RAISE vMyException;
         ELSE
            BEGIN
               UPDATE emob.FP_USER_LOGIN
                  SET LOGIN_STATUS = 'Y'
                WHERE     UPPER (USER_CODE) = UPPER (p_username)
                      AND SESSION_ID = vSessionId
                      AND LOGIN_STATUS = 'N'
                      AND TRUNC (CREATE_DATE) = TRUNC (SYSDATE);
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrCode := 'OTH';
                  vErrorMessage := 'User Finger Update Error. - ' || SQLERRM;
                  RAISE vMyException;
            END;

            BEGIN
               UPDATE emob.MB_USER_MST
                  SET inv_login_cnt = 0
                WHERE UPPER (USER_CODE) = UPPER (p_username);
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrCode := 'OTH';
                  vErrorMessage := 'Update Error Invalid Free. - ' || SQLERRM;
                  RAISE vMyException;
            END;

            RETURN TRUE;
         END IF;
      END IF;
   END IF;
EXCEPTION
   WHEN vMyException
   THEN
      BEGIN
         EMOB.PRC_ACCESS_LOG (pUserCode            => UPPER (p_username),
                              pUserId              => vUserID,
                              pCaptchaValue        => NULL,
                              pValidLogin          => 'N',
                              pFailedCode          => vErrCode,
                              pFaileddReson        => vErrorMessage,
                              pInvalidLoginCount   => vInvLoginCnt,
                              pLogId               => vLogID);
      EXCEPTION
         WHEN OTHERS
         THEN
            vErrorMessage :=
               'PRC_ACCESS_LOG log process calling problem. - ' || SQLERRM;
      END;


      IF vInvLoginCnt >= vMaxInvLogMailSend
      THEN
         BEGIN
            emob.abs_access_audit.
             login_fail_mail (
               pModuleDate         => TRUNC (SYSDATE),
               pUserCode           => UPPER (p_username),
               pFailedCode         => vErrCode,
               pSmtpHost           => '10.11.1.204',
               pInvLoginCnt        => vInvLoginCnt,
               pUserMailId         => vUserMailId,
               pSendCc             => 'kamrulfardaus@yahoo.com',
               pSendBcc            => NULL,
               pSendFrom           => 'agent.support@bankasia.info',
               pUserMobileNo       => NULL,
               pSubject            => 'Agent Banking Invalid Login - '
                                     || UPPER (p_username),
               pSmtpPort           => 25,
               pMaxInvLoginAllow   => vMaxInvLoginAllow,
               pErrorFlag          => vErrorFlag2,
               pErrorMessage       => vErrorMessage2);
         EXCEPTION
            WHEN OTHERS
            THEN
               vErrorMessage :=
                  'User Send Mail Process Calling Error. - ' || SQLERRM;
         END;

         IF NVL (vErrorFlag2, 'N') = 'Y'
         THEN
            vErrorMessage := vErrorMessage2;
         END IF;
      END IF;

      RAISE_APPLICATION_ERROR (-20001, vErrorMessage);
      RETURN FALSE;
END;
/
