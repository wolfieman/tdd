<?xml version='1.0' ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:a="http://schemas.benefitfocus.com/events/general/2011/1/1/notificationRequest"
                xmlns:b="http://bf.bts.applications.ESB.schema.Export.Fulfillment.AetnaOMS"
                xmlns:c="http://schemas.benefitfocus.com/common/general/2010/1/1/personName"
                xmlns:d="http://schemas.benefitfocus.com/member/general/2010/1/1/memberBenefitIdentification"
                xmlns:e="http://schemas.benefitfocus.com/common/general/2010/1/1/currency"
                xmlns:f="http://schemas.benefitfocus.com/common/general/2010/2/1/address"
                xmlns:ext="urn:extension-lib:functions"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                extension-element-prefixes="ext">


  <!-- Comment out the script block before checking in -->
<!--
  <msxsl:script language="C#" implements-prefix="ext">
    <![CDATA[
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public string GetCurrentDateTime()
        {
            return System.DateTime.Now.ToString("s");
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public string GetCurrentDateTime(string format)
        {
            return System.DateTime.Now.ToString(format);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="dateTimeString"></param>
        /// <param name="format"></param>
        /// <returns></returns>
        public string FormatDateTime(string dateTimeString, string format)
        {
            DateTime dt;

            if (DateTime.TryParse(dateTimeString, out dt))
            {
                return dt.ToString(format);
            }
            else
            {
                return string.Empty;
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="dateTimeString"></param>
        /// <param name="yearsToAdd"></param>
        /// <param name="monthsToAdd"></param>
        /// <param name="daysToAdd"></param>
        /// <param name="format"></param>
        /// <returns></returns>
        public string DateAdd(string dateTimeString, int yearsToAdd, int monthsToAdd, int daysToAdd, string format)
        {
            DateTime dt;

            if (DateTime.TryParse(dateTimeString, out dt))
            {
                dt = dt.AddYears(yearsToAdd);
                dt = dt.AddMonths(monthsToAdd);
                dt = dt.AddDays(daysToAdd);
                return dt.ToString(format);
            }
            else
            {
                return string.Empty;
            }
        }
        
        /// <summary>
        /// 
        /// </summary>
        /// <param name="dt"></param>
        /// <returns></returns>
        public string DayOfTheMonth(DateTime dt)
        {
            string day = string.Empty;
            string suffix = string.Empty;

            if(dt != null)
            {
                int lastDigit = dt.Day % 10;
                switch(lastDigit)
                {
                    case 1:
                        suffix = "st";
                        break;

                    case 2:
                        suffix = "nd";
                        break;

                    case 3:
                        suffix = "rd";
                        break;

                    default:
                        suffix = "th";
                        break;                      
                }

                day = string.Format("{0}{1} of the month", dt.Day, suffix);
            }

            return day;
        }
        
]]>
  </msxsl:script>
-->

  <xsl:decimal-format
  decimal-separator="." grouping-separator="," NaN="" infinity=""/>

  <xsl:template match="/">
    <b:OMS>
      <HeaderContainer>
        <Header>
          <WS-HEADER-DATE-YYYY>
            <xsl:value-of select="ext:GetCurrentDateTime('yyyy')"/>
          </WS-HEADER-DATE-YYYY>
          <WS-HEADER-DATE-MM>
            <xsl:value-of select="ext:GetCurrentDateTime('MM')"/>
          </WS-HEADER-DATE-MM>
          <WS-HEADER-DATE-DD>
            <xsl:value-of select="ext:GetCurrentDateTime('dd')"/>
          </WS-HEADER-DATE-DD>
          <WS-HEADER-EOL></WS-HEADER-EOL>
          <WS-HEADER-TIME-HH>
            <xsl:value-of select="ext:GetCurrentDateTime('hh')"/>
          </WS-HEADER-TIME-HH>
          <WS-HEADER-TIME-MM>
            <xsl:value-of select="ext:GetCurrentDateTime('mm')"/>
          </WS-HEADER-TIME-MM>
          <WS-HEADER-EOL></WS-HEADER-EOL>
          <WS-HEADER-JOB-NAME />
          <WS-HEADER-EOL></WS-HEADER-EOL>
          <WS-HEADER-FILE-DESCRIPTION>
            <xsl:value-of select="'Benefitfocus Daily Fulfillment Feed'"/>
          </WS-HEADER-FILE-DESCRIPTION>
          <WS-HEADER-FILLER></WS-HEADER-FILLER>
          <WS-HEADER-EOL>*</WS-HEADER-EOL>
        </Header>
      </HeaderContainer>

      <xsl:for-each select="//*[local-name()='notificationRequestType' and ./*[local-name()='channel']='PRINT']">

        <!-- Define and set variables -->
        <xsl:variable name="famBenefitNewRate">
          <xsl:call-template name="GetNumericValue">
            <xsl:with-param name="value" select="./*[local-name()='enrollmentInfo']/*[local-name()='familyMember']/*[local-name()='memberBenefit'][1]/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="famBenefitOldRate">
          <xsl:call-template name="GetNumericValue">
            <xsl:with-param name="value" select="./*[local-name()='enrollmentInfo']/*[local-name()='familyMember']/*[local-name()='memberBenefit'][1]/*[local-name()='oldPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="mbrBenefitNewRate" >
          <xsl:call-template name="GetNumericValue">
            <xsl:with-param name="value" select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="mbrBenefitOldRate" >
          <xsl:call-template name="GetNumericValue">
            <xsl:with-param name="value" select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="billPackNewRate" >
          <xsl:call-template name="GetNumericValue">
            <xsl:with-param name="value" select="./*[local-name()='enrollmentInfo']/*[local-name()='billPackage'][1]/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="billPackOldRate" >
          <xsl:call-template name="GetNumericValue">
            <xsl:with-param name="value" select="./*[local-name()='enrollmentInfo']/*[local-name()='billPackage'][1]/*[local-name()='oldPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="mbrPersonalNewRate"  >
          <xsl:call-template name="GetNumericValue">
            <xsl:with-param name="value" select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="mbrPersonalOldRate"  >
          <xsl:call-template name="GetNumericValue">
            <xsl:with-param name="value" select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='oldPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
          </xsl:call-template>
        </xsl:variable>


        <BeginGroupContainer>
          <BeginGroup>
            <WS-GT-LETTER-CODE>
              <xsl:value-of select="./*[local-name()='templateId']"/>
            </WS-GT-LETTER-CODE>
            <WS-GT-REQ-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='printDate'], 'MM/dd/yyyy')"/>
            </WS-GT-REQ-DATE>
            <WS-GT-POLICY-HOLDER-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='billPackage']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="0" />
              </xsl:call-template>
            </WS-GT-POLICY-HOLDER-NAME>
            <WS-GT-SERVICE-BROKER-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='benefitAgentInformation' and ./*[local-name()='agentType']='SERVICE_BROKER']/*[local-name()='agentInformation']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="0" />
              </xsl:call-template>
            </WS-GT-SERVICE-BROKER-NAME>
            <WS-GT-APP-BROKER-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='benefitAgentInformation' and ./*[local-name()='agentType']='APPLICATION_BROKER']/*[local-name()='agentInformation']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="0" />
              </xsl:call-template>
            </WS-GT-APP-BROKER-NAME>
            <WS-GT-APP-GA-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='benefitAgentInformation' and ./*[local-name()='agentType']='APPLICATION_GENERAL_AGENT']/*[local-name()='agentInformation']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="0" />
              </xsl:call-template>
            </WS-GT-APP-GA-NAME>
            <WS-GT-DEPENDENT-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='familyMember']/*[local-name()='memberPersonalIdentification']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="0" />
              </xsl:call-template>
            </WS-GT-DEPENDENT-NAME>
            <WS-GT-SUBSCRIBER-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="0" />
              </xsl:call-template>
            </WS-GT-SUBSCRIBER-NAME>
            <WS-GT-MEMBER-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="0" />
              </xsl:call-template>
            </WS-GT-MEMBER-NAME>
            <WS-GT-PRIMARY-APPLICANT-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="0" />
              </xsl:call-template>
            </WS-GT-PRIMARY-APPLICANT-NAME>
            <WS-GT-MAILTO-ADDR-NAME>
              <xsl:call-template name="GetPersonName">
                <xsl:with-param name="personObject" select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='personName']" />
                <xsl:with-param name="includeMN" select="1" />
              </xsl:call-template>
            </WS-GT-MAILTO-ADDR-NAME>
            <WS-GT-MAILTO-ADDRESS-LINE1>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']/*[local-name()='primaryStreet']"/>
            </WS-GT-MAILTO-ADDRESS-LINE1>
            <WS-GT-MAILTO-ADDRESS-LINE2>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']/*[local-name()='secondaryStreet']"/>
            </WS-GT-MAILTO-ADDRESS-LINE2>
            <WS-GT-MAILTO-ADDRESS-LINE3></WS-GT-MAILTO-ADDRESS-LINE3>
            <WS-GT-MAILTO-CITY>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']/*[local-name()='city']"/>
            </WS-GT-MAILTO-CITY>
            <WS-GT-MAILTO-STATE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']/*[local-name()='state']"/>
            </WS-GT-MAILTO-STATE>
            <WS-GT-MAILTO-ZIP>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']/*[local-name()='postalCode']"/>
            </WS-GT-MAILTO-ZIP>
            <WS-GT-MAILTO-COUNTRY-NAME></WS-GT-MAILTO-COUNTRY-NAME>

            <!-- left blank because Aetna did not provide values -->
            <WS-GT-RET-ADDRESS-LINE1></WS-GT-RET-ADDRESS-LINE1>
            <WS-GT-RET-ADDRESS-LINE2></WS-GT-RET-ADDRESS-LINE2>
            <WS-GT-RET-ADDRESS-LINE3></WS-GT-RET-ADDRESS-LINE3>
            <WS-GT-RET-ADDRESS-LINE4></WS-GT-RET-ADDRESS-LINE4>
            <WS-GT-RET-CITY></WS-GT-RET-CITY>
            <WS-GT-RET-STATE></WS-GT-RET-STATE>
            <WS-GT-RET-ZIP></WS-GT-RET-ZIP>

            <WS-GT-FOREIGN-IND></WS-GT-FOREIGN-IND>
            <WS-GT-PRINT-SUPPRESS-IND></WS-GT-PRINT-SUPPRESS-IND>

            <WS-GT-CUMB-ID>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='memberBenefitIdentification']/*[local-name()='altMemberBenefitId']"/>
            </WS-GT-CUMB-ID>
            <WS-GT-SEQ-NUM>0</WS-GT-SEQ-NUM>
            <WS-GT-INDIV-CUST-GRP-IDENTIFIER>
              <xsl:value-of select="./*[local-name()='billingGroupId']"/>
            </WS-GT-INDIV-CUST-GRP-IDENTIFIER>
            <WS-GT-TRANS-ID>
              <xsl:value-of select="./*[local-name()='transId']"/>
            </WS-GT-TRANS-ID>
            <WS-GT-CARRIER-NAME>AIPS</WS-GT-CARRIER-NAME>
            <WS-GT-MEMBER-ID>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='memberBenefitIdentification']/*[local-name()='memberBenefitId']"/>
            </WS-GT-MEMBER-ID>
            <WS-GT-REINSTATEMENT-EFF-DT>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='planEffectiveDate'], 'MM/dd/yyyy')"/>
            </WS-GT-REINSTATEMENT-EFF-DT>
            <WS-GT-NEW-RATE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-NEW-RATE>
            <WS-GT-CURRENT-RATE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='oldPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-CURRENT-RATE>
            <WS-GT-NEW-BP-RATE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='billPackage']/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-NEW-BP-RATE>
            <WS-GT-CURRENT-BP-RATE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='billPackage']/*[local-name()='oldPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-CURRENT-BP-RATE>
            <WS-GT-NEW-SUB-RATE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-NEW-SUB-RATE>
            <WS-GT-CURRENT-SUB-RATE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='oldPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-CURRENT-SUB-RATE>
            <WS-GT-RATE-MONTH>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='rateEffectiveDate'],'MMMM')"/>
            </WS-GT-RATE-MONTH>
            <WS-GT-COV-TYPE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='coverageLevelName']"/>
            </WS-GT-COV-TYPE>
            <WS-GT-RATE-GUAR-BEG-DATE>
              <xsl:if test="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/@originalEffectiveDate != ''">
                <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/@originalEffectiveDate, 'MM/dd/yyyy')"/>
              </xsl:if>
            </WS-GT-RATE-GUAR-BEG-DATE>
            <WS-GT-END-OF-MONTHLY-BILLING-CYCLE>
              <xsl:value-of select="ext:DateAdd(./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='planEffectiveDate'],0,1,-1,'MM/dd/yyyy')"/>
            </WS-GT-END-OF-MONTHLY-BILLING-CYCLE>
            <WS-GT-PREM-DUE-DATE>
              <xsl:if test="./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/@originalEffectiveDate != ''">
                <xsl:value-of select="ext:DayOfTheMonth(./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/@originalEffectiveDate)"/>
              </xsl:if>
            </WS-GT-PREM-DUE-DATE>
            <WS-GT-POLICY-NUMBER>
              <xsl:value-of select="./*[local-name()='policyId']"/>
            </WS-GT-POLICY-NUMBER>
            <WS-GT-CURR-DATE-PLUS15>
              <xsl:value-of select="ext:DateAdd(ext:GetCurrentDateTime(), 0,0,15, 'MM/dd/yyyy')"/>
            </WS-GT-CURR-DATE-PLUS15>
            <WS-GT-EFT-REJECT-MSG></WS-GT-EFT-REJECT-MSG>
            <WS-GT-ALT-PLAN-NAME1>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='altMemberBenefit'][1]/*[local-name()='planName']"/>
            </WS-GT-ALT-PLAN-NAME1>
            <WS-GT-ALT-PLAN-RATE1>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='altMemberBenefit'][1]/*[local-name()='planRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-ALT-PLAN-RATE1>
            <WS-GT-ALT-PLAN-NAME2>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='altMemberBenefit'][2]/*[local-name()='planName']"/>
            </WS-GT-ALT-PLAN-NAME2>
            <WS-GT-ALT-PLAN-RATE2>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='altMemberBenefit'][2]/*[local-name()='planRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-ALT-PLAN-RATE2>
            <WS-GT-ALT-PLAN-NAME3>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='altMemberBenefit'][3]/*[local-name()='planName']"/>
            </WS-GT-ALT-PLAN-NAME3>
            <WS-GT-ALT-PLAN-RATE3>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='altMemberBenefit'][3]/*[local-name()='planRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-ALT-PLAN-RATE3>
            <WS-GT-G-TERM-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/@terminationDate, 'MM/dd/yyyy')"/>
            </WS-GT-G-TERM-DATE>
            <WS-GT-NEW-TERM-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/@newTerminationDate, 'MM/dd/yyyy')"/>
            </WS-GT-NEW-TERM-DATE>
            <WS-GT-DEP-MTH-PRE>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='familyMember']/*[local-name()='memberBenefit'][1]/*[local-name()='newPlanRate']/*[local-name()='memberCost']/*[local-name()='currency']/*[local-name()='amount']"/>
            </WS-GT-DEP-MTH-PRE>
            <WS-GT-DEP-MTH-PRE-EFF-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='familyMember']/*[local-name()='memberBenefit'][1]/*[local-name()='planEffectiveDate'], 'MM/dd/yyyy')"/>
            </WS-GT-DEP-MTH-PRE-EFF-DATE>
            <WS-GT-NEW-COMBINED-MTH-PREMIUM>
              <xsl:call-template name="formatDollar">
                <xsl:with-param name="value" select="$famBenefitNewRate + $mbrBenefitNewRate "/>
              </xsl:call-template>
            </WS-GT-NEW-COMBINED-MTH-PREMIUM>
            <WS-GT-DEPENDENT-TERM-EFF-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='familyMember']/*[local-name()='memberPersonalIdentification']/@terminationDate, 'MM/dd/yyyy')"/>
            </WS-GT-DEPENDENT-TERM-EFF-DATE>
            <WS-GT-RENEWAL-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='rateEffectiveDate'], 'MM/dd/yyyy')"/>
            </WS-GT-RENEWAL-DATE>
            <WS-GT-PREVOIUS-PLAN-NAME>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='oldPlanName']"/>
            </WS-GT-PREVOIUS-PLAN-NAME>
            <WS-GT-NEW-PLAN-NAME>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='newPlanName']"/>
            </WS-GT-NEW-PLAN-NAME>
            <WS-GT-PLAN-TPID>
              <xsl:value-of select="./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='planID']"/>
            </WS-GT-PLAN-TPID>
            <WS-GT-EFF-DATE-OF-PLAN-CHANGE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='memberBenefit'][1]/*[local-name()='planEffectiveDate'], 'MM/dd/yyyy')"/>
            </WS-GT-EFF-DATE-OF-PLAN-CHANGE>
            <WS-GT-RATE-INCR-AMT>
              <xsl:call-template name="formatDollar">
                <xsl:with-param name="value" select="$famBenefitNewRate + $mbrBenefitNewRate - $mbrBenefitOldRate" />
              </xsl:call-template>
            </WS-GT-RATE-INCR-AMT>
            <WS-GT-RATE-INCR-PERCENT>
              <xsl:call-template name="formatPercent">
                <xsl:with-param name="value" select="($famBenefitNewRate + $mbrBenefitNewRate - $mbrBenefitOldRate) div $mbrBenefitOldRate"/>
              </xsl:call-template>
            </WS-GT-RATE-INCR-PERCENT>
            <WS-GT-RATE-INCR-BP-AMT>
              <xsl:call-template name="formatDollar">
                <xsl:with-param name="value" select="$famBenefitNewRate + $billPackNewRate - $billPackOldRate"/>
              </xsl:call-template>
            </WS-GT-RATE-INCR-BP-AMT>
            <WS-GT-RATE-INCR-BP-PERCENT>
              <xsl:call-template name="formatPercent">
                <xsl:with-param name="value" select="($famBenefitNewRate + $billPackNewRate - $billPackOldRate) div $billPackOldRate"/>
              </xsl:call-template>
            </WS-GT-RATE-INCR-BP-PERCENT>
            <WS-GT-RATE-INCR-SUB-AMT>
              <xsl:call-template name="formatDollar">
                <xsl:with-param name="value" select="$famBenefitNewRate + $mbrPersonalNewRate - $mbrPersonalOldRate"/>
              </xsl:call-template>
            </WS-GT-RATE-INCR-SUB-AMT>
            <WS-GT-RATE-INCR-SUB-PERCENT>
              <xsl:call-template name="formatPercent">
                <xsl:with-param name="value" select="($famBenefitNewRate + $mbrPersonalNewRate - $mbrPersonalOldRate) div $mbrPersonalOldRate"/>
              </xsl:call-template>
            </WS-GT-RATE-INCR-SUB-PERCENT>
            <WS-GT-G-SER-BRO-EFF-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='benefitAgentInformation' and ./*[local-name()='agentType']='SERVICE_BROKER']/*[local-name()='effectiveDate'], 'MM/dd/yyyy')"/>
            </WS-GT-G-SER-BRO-EFF-DATE>
            <WS-GT-G-ADD-EFF-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']/@effectiveDate, 'MM/dd/yyyy')"/>
            </WS-GT-G-ADD-EFF-DATE>
            <WS-GT-BP-EFF-DATE>
              <xsl:value-of select="ext:FormatDateTime(./*[local-name()='enrollmentInfo']/*[local-name()='billPackage']/*[local-name()='effectiveDate'],'MM/dd/yyyy')"/>
            </WS-GT-BP-EFF-DATE>
            <WS-GT-SPACE></WS-GT-SPACE>
            <WS-GT-EOL>*</WS-GT-EOL>
          </BeginGroup>
          <EndGroupContainer>
            <EndGroup>
              <WS-GT-SPACE></WS-GT-SPACE>
              <WS-GT-EOL>*</WS-GT-EOL>
            </EndGroup>
          </EndGroupContainer>
        </BeginGroupContainer>
      </xsl:for-each>
      <TrailerContainer>
        <Trailer>
          <WS-TRLR-DOC-CNT>
            <xsl:value-of select="count(//*[local-name()='notificationRequestType'  and ./*[local-name()='channel']='PRINT'])"/>
          </WS-TRLR-DOC-CNT>
          <WS-TRLR-CHK-CNT>
            <xsl:value-of select="'0000000000'"/>
          </WS-TRLR-CHK-CNT>
          <WS-TRLR-CHK-TTL>
            <xsl:value-of select="'00000000000.00'"/>
          </WS-TRLR-CHK-TTL>
          <WS-TRLR-FILLER></WS-TRLR-FILLER>
          <WS-TRLR-EOL>*</WS-TRLR-EOL>
        </Trailer>
      </TrailerContainer>
    </b:OMS>
  </xsl:template>

  <xsl:template name="GetPersonName">
    <xsl:param name="personObject"/>
    <xsl:param name="includeMN"/>
    <xsl:if test="$includeMN = 1">
      <xsl:value-of select="concat($personObject/*[local-name()='firstName'], ' ', $personObject/*[local-name()='middleName'], ' ', $personObject/*[local-name()='lastName'])"/>
    </xsl:if>
    <xsl:if test="$includeMN = 0">
      <xsl:value-of select="concat($personObject/*[local-name()='firstName'], ' ', $personObject/*[local-name()='lastName'])"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="GetMailToInfoSet">
    <xsl:param name="personObject"/>
    <xsl:param name="addressObject"/>

  </xsl:template>

  <xsl:template name="GetBillPackageHolderMailToInfo">
    <xsl:param name="notificationObject"/>
    <xsl:call-template name="GetMailToInfoSet">
      <xsl:with-param name="personObject" select="$notificationObject/*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='personName']" />
      <xsl:with-param name="addressObject" select="$notificationObject/*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']" />
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="GetMemberMailToInfo">
    <xsl:param name="notificationObject"/>
    <xsl:call-template name="GetMailToInfoSet">
      <xsl:with-param name="personObject" select="$notificationObject/*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='personName']" />
      <xsl:with-param name="addressObject" select="$notificationObject/*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']" />
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="GetSubscriberMailToInfo">
    <xsl:param name="notificationObject"/>
    <xsl:call-template name="GetMailToInfoSet">
      <xsl:with-param name="personObject" select="$notificationObject/*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='personName']" />
      <xsl:with-param name="addressObject" select="$notificationObject/*[local-name()='enrollmentInfo']/*[local-name()='memberPersonalIdentification']/*[local-name()='address']" />
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="formatDollar">
    <xsl:param name="value" />
    <xsl:value-of select="format-number($value, '##0.00')"/>
  </xsl:template>

  <xsl:template name="formatPercent">
    <xsl:param name="value" />
    <xsl:value-of select="format-number($value, '##0.00%')"/>
  </xsl:template>

  <xsl:template name="GetNumericValue">
    <xsl:param name="value" />
    <xsl:if test="not(string(number($value)) = 'NaN')">
      <xsl:value-of select="$value"/>
    </xsl:if>
    <xsl:if test="string(number($value)) = 'NaN'">
      <xsl:value-of select="'0'"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
<!-- Stylus Studio meta-information - (c) 2004-2009. Progress Software Corporation. All rights reserved.

<metaInformation>
	<scenarios/>
	<MapperMetaTag>
		<MapperInfo srcSchemaPathIsRelative="yes" srcSchemaInterpretAsXML="no" destSchemaPath="..\bf.bts.applications.ESB.schema.Export\Fulfillment\AetnaOMS.xsd" destSchemaRoot="OMS" destSchemaPathIsRelative="yes" destSchemaInterpretAsXML="no">
			<SourceSchema srcSchemaPath="file:///d:/enterpriseServices/trunk/enterpriseSchemas/src/main/xsd/schemas/benefitfocus/com/events/general/2011/1/1/notificationRequest.xsd" srcSchemaRoot="notificationRequestType" AssociatedInstance=""
			              loaderFunction="document" loaderFunctionUsesURI="no"/>
		</MapperInfo>
		<MapperBlockPosition>
			<template match="/">
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-DATE-YYYY/xsl:value-of" x="461" y="72"/>
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-DATE-MM/xsl:value-of" x="501" y="90"/>
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-DATE-DD/xsl:value-of" x="461" y="108"/>
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-EOL/xsl:value-of" x="501" y="126"/>
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-TIME-HH/xsl:value-of" x="461" y="144"/>
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-TIME-MM/xsl:value-of" x="501" y="162"/>
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-JOB-NAME/xsl:value-of" x="461" y="180"/>
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-FILE-DESCRIPTION/xsl:value-of" x="501" y="198"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-POLICY-HOLDER-NAME/xsl:value-of" x="421" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-DEPENDENT-NAME/xsl:value-of" x="381" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-SUBSCRIBER-NAME/xsl:value-of" x="341" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MEMBER-NAME/xsl:value-of" x="301" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-PRIMARY-APPLICANT-NAME/xsl:value-of" x="261" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-SEQ-NUM/xsl:value-of" x="221" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-CARRIER-NAME/xsl:value-of" x="181" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-NEW-COMBINED-MTH-PREMIUM/xsl:value-of" x="141" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RATE-INCR-AMT/xsl:value-of" x="101" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RATE-INCR-BP-AMT/xsl:value-of" x="61" y="162"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-EOL/xsl:value-of" x="21" y="162"/>
				<block path="b:OMS/BeginGroupContainer/EndGroupContainer/EndGroup/WS-GT-EOL/xsl:value-of" x="261" y="122"/>
				<block path="b:OMS/TrailerContainer/Trailer/WS-TRLR-DOC-CNT/xsl:value-of" x="421" y="122"/>
				<block path="b:OMS/TrailerContainer/Trailer/WS-TRLR-CHK-CNT/xsl:value-of" x="381" y="122"/>
				<block path="b:OMS/TrailerContainer/Trailer/WS-TRLR-CHK-TTL/xsl:value-of" x="341" y="122"/>
				<block path="b:OMS/TrailerContainer/Trailer/WS-TRLR-EOL/xsl:value-of" x="301" y="122"/>
				<block path="b:OMS/HeaderContainer/Header/WS-HEADER-FILLER/xsl:value-of" x="401" y="71"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MAILTO-ADDR-NAME/xsl:value-of" x="247" y="251"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MAILTO-ADDRESS-LINE1/xsl:value-of" x="263" y="276"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MAILTO-ADDRESS-LINE2/xsl:value-of" x="300" y="292"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MAILTO-ADDRESS-LINE3/xsl:value-of" x="458" y="217"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MAILTO-CITY/xsl:value-of" x="464" y="245"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MAILTO-STATE/xsl:value-of" x="212" y="219"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MAILTO-ZIP/xsl:value-of" x="219" y="247"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-MAILTO-COUNTRY-NAME/xsl:value-of" x="200" y="199"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RET-ADDRESS-LINE1/xsl:value-of" x="384" y="228"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RET-ADDRESS-LINE2/xsl:value-of" x="393" y="255"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RET-ADDRESS-LINE3/xsl:value-of" x="433" y="274"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RET-ADDRESS-LINE4/xsl:value-of" x="502" y="229"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RET-CITY/xsl:value-of" x="507" y="259"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RET-STATE/xsl:value-of" x="480" y="280"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-RET-ZIP/xsl:value-of" x="513" y="292"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-FOREIGN-IND/xsl:value-of" x="365" y="298"/>
				<block path="b:OMS/BeginGroupContainer/BeginGroup/WS-GT-PRINT-SUPPRESS-IND/xsl:value-of" x="360" y="266"/>
			</template>
		</MapperBlockPosition>
		<TemplateContext></TemplateContext>
		<MapperFilter side="source"></MapperFilter>
	</MapperMetaTag>
</metaInformation>
-->