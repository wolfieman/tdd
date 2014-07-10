<xsl:stylesheet
        version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <!-- Output Type Declaration-->
  <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>

  <!-- Entry Point -->
  <xsl:template match="/">
    <eDirectFile>
      <xsl:attribute name="xsi:noNamespaceSchemaLocation">eDirect-EBS Trigger V1.0.xsd</xsl:attribute>
      <eDirectRecord>
        <xsl:call-template name="processEvent"/>
      </eDirectRecord>
    </eDirectFile>
  </xsl:template>

  <xsl:template name="processEvent">
    <xsl:call-template name="processHeader"/>
    <xsl:call-template name="processFamilies"/>
    <xsl:call-template name="processTrailer"/>
  </xsl:template>

  <xsl:template name="processHeader">
    <HeaderInfo>
      <HeaderRecordType>000</HeaderRecordType>
      <HeaderTransactionID>
        <xsl:value-of select="substring(/BillingSignificantEvents/HeaderInfo/HeaderTransactionID,1,36)"/>
      </HeaderTransactionID>
      <HeaderTransactionType>EBSBATINTF</HeaderTransactionType>
      <HeaderDateTime>
        <xsl:value-of select="substring(/BillingSignificantEvents/HeaderInfo/HeaderDateTime,1,26)"/>
      </HeaderDateTime>
      <HeaderSenderID>BENEFIT_FOCUS_EDIRECT</HeaderSenderID>
      <HeaderRecieverID>AETNA_EDI_GATEWAY</HeaderRecieverID>
      <HeaderTestProdID>
        <xsl:value-of select="/BillingSignificantEvents/HeaderInfo/HeaderTestProdID"/>
      </HeaderTestProdID>
    </HeaderInfo>
  </xsl:template>

  <xsl:template name="processFamilies">
    <xsl:for-each select=".//billingSignificantEventInformation">
      <xsl:variable name="bse" select="."/>
      <xsl:call-template name="processFamily">
        <xsl:with-param name="bse" select="$bse"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:for-each select=".//BillingSignificantEventInformation">
      <xsl:variable name="bse" select="."/>
      <xsl:call-template name="processFamily">
        <xsl:with-param name="bse" select="$bse"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:for-each select=".//BillingSignificantEventInformation">
      <xsl:if test="string-length(billInformation/billAction/text()) > 0">
        <xsl:variable name="bse" select="."/>
        <xsl:call-template name="processSpecialRequest">
          <xsl:with-param name="bse" select="$bse"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="processFamily">
    <xsl:param name="bse"/>
    <xsl:variable name="hasNonRiderTransactions">
      <xsl:call-template name="containsNonRiderTransactions">
        <xsl:with-param name="bse" select="$bse"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="($bse/memberBenefit and string-length($hasNonRiderTransactions) > 0) or ($bse/billInformation and $bse/applicationId)">
      <FamilyTransactionRecord>
        <xsl:call-template name="processBillPackageInfo">
          <xsl:with-param name="bse" select="$bse"/>
        </xsl:call-template>
        <xsl:for-each select="$bse/memberBenefit/subscriber/memberIdentificationReferenceId[not(text() = preceding-sibling::memberBenefit/subscriber/memberIdentificationReferenceId/text())]">
          <xsl:if test="../../productType != 'RIDER'">
            <xsl:call-template name="processSubscriber">
              <xsl:with-param name="bse" select="$bse"/>
              <xsl:with-param name="subscriberMemberReferenceId" select="."/>
              <xsl:with-param name="planName" select="../../planName"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:for-each>
      </FamilyTransactionRecord>
    </xsl:if>
  </xsl:template>

  <xsl:template name="containsNonRiderTransactions">
    <xsl:param name="bse"/>
    <xsl:choose>
      <xsl:when test="$bse/memberIdentification[@referenceId = $bse/transaction/transactionObjectReferenceId] or $bse/memberPersonalIdentification[@referenceId = $bse/transaction/transactionObjectReferenceId]">
        true
      </xsl:when>
      <xsl:when test="$bse/memberBenefit/productType = 'RIDER'">
        false
      </xsl:when>
      <xsl:otherwise>
        true
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="processBillPackageInfo">
    <!-- bse == billing significant event -->
    <xsl:param name="bse"/>
    <xsl:variable name="memberBenefitInfo" select="$bse/memberBenefit"/>
    <xsl:variable name="carrierBillingInfo" select="$memberBenefitInfo/carrierBillingInformation"/>
    <xsl:variable name="billInformation" select="$bse/billInformation"/>
    <xsl:variable name="newBillPackage">
      <xsl:call-template name="isNewBillPackage">
        <xsl:with-param name="bse" select="$bse"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="changeBillPackage">
      <xsl:call-template name="isChangeBillPackage">
        <xsl:with-param name="bse" select="$bse"/>
      </xsl:call-template>
    </xsl:variable>

    <BillPackage>
      <MemberTransactionRecordType>FAM</MemberTransactionRecordType>
      <FamilyID>
        <xsl:value-of select="substring($bse/applicationId,1,25)"/>
      </FamilyID>

      <xsl:if test="string-length($changeBillPackage) > 0 and $bse/newApplicationId/text() and not($bse/applicationId/text() = $bse/newApplicationId/text()) and
                     not($bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
        <ChangedFamilyID>
          <xsl:value-of select="substring($bse/newApplicationId,0,25)"/>
        </ChangedFamilyID>
      </xsl:if>
      <xsl:if test="$carrierBillingInfo/billingGroupId and not($bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
        <IVLCustGroupID>
          <xsl:value-of select="substring($carrierBillingInfo/billingGroupId,1,9)"/>
        </IVLCustGroupID>
      </xsl:if>
      <xsl:if test="$billInformation/carrierBillingInformation/billingGroupId and not($bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
        <IVLCustGroupID>
          <xsl:value-of select="substring($billInformation/carrierBillingInformation/billingGroupId,1,9)"/>
        </IVLCustGroupID>
      </xsl:if>
      <xsl:if test="$carrierBillingInfo/billingUnitId and not($bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
        <IVLBillPackageNo>
          <xsl:value-of select="substring($carrierBillingInfo/billingUnitId,1,4)"/>
        </IVLBillPackageNo>
      </xsl:if>
      <xsl:if test="$billInformation/carrierBillingInformation/billingUnitId and not($bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
        <IVLBillPackageNo>
          <xsl:value-of select="substring($billInformation/carrierBillingInformation/billingUnitId,1,4)"/>
        </IVLBillPackageNo>
      </xsl:if>
      <xsl:if test="$bse/transaction/memberTransactionTypes/text() = 'NEW_ENROLLMENT' or $bse/transaction/memberTransactionTypes/text() = 'CARRIER_BILLING_INFORMATION' or
            $bse/transaction/memberTransactionTypes/text() = 'ADD_OR_UPDATE_PAYMENT_METHOD' or $bse/transaction/memberTransactionTypes/text() = 'ADD_SUBSCRIBER' or
            (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
        <LineOfBusiness>IVL</LineOfBusiness>
      </xsl:if>
      <PostedDTS>
        <xsl:call-template name="translateDateTime">
          <xsl:with-param name="rawDate" select="$bse/eventDate"/>
          <xsl:with-param name="formatted" select="true()"/>
        </xsl:call-template>
      </PostedDTS>
      <xsl:if test="string-length($newBillPackage) > 0 or string-length($changeBillPackage) > 0">
        <BillRecordType>
          <xsl:choose>
            <xsl:when test="string-length($newBillPackage) > 0 or (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">BPN</xsl:when>
            <xsl:when test="string-length($changeBillPackage) > 0">BPM</xsl:when>
          </xsl:choose>
        </BillRecordType>
      </xsl:if>
      <xsl:if test="string-length($newBillPackage) > 0 or string-length($changeBillPackage) > 0">
        <xsl:if test="$carrierBillingInfo/responsibleParty/personName/firstName/text()">
          <CustomerFirstName>
            <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/personName/firstName, 1, 25)"/>
          </CustomerFirstName>
        </xsl:if>
        <xsl:if test="$carrierBillingInfo/responsibleParty/personName/middleName/text()">
          <CustomerMiddleInitial>
            <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/personName/middleName, 1, 1)"/>
          </CustomerMiddleInitial>
        </xsl:if>
        <xsl:if test="$carrierBillingInfo/responsibleParty/personName/lastName/text()">
          <CustomerLastName>
            <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/personName/lastName, 1 , 25)"/>
          </CustomerLastName>
        </xsl:if>
        <xsl:if test="string-length($newBillPackage) > 0 or string-length($changeBillPackage) > 0 or $bse/transaction/billingTransactionTypes/text()">
          <BillEffectiveDate>
            <xsl:choose>
              <xsl:when test="$billInformation/effectiveDate">
                <xsl:call-template name="translateDate">
                  <xsl:with-param name="rawDate" select="$billInformation/effectiveDate"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="translateDate">
                  <xsl:with-param name="rawDate" select="$memberBenefitInfo/coverageDates/originalEffectiveDate"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </BillEffectiveDate>
        </xsl:if>
        <xsl:if test="string-length($newBillPackage) > 0 or (string-length($changeBillPackage) > 0 and ($bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE' or $bse/transaction/memberTransactionTypes/text() = 'CARRIER_BILLING_INFORMATION'))">
          <xsl:if test="$carrierBillingInfo/responsibleParty/address/primaryStreet/text()">
            <USAddressLine1>
              <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/address/primaryStreet,1,64)"/>
            </USAddressLine1>
          </xsl:if>
          <xsl:if test="$carrierBillingInfo/responsibleParty/address/secondaryStreet/text()">
            <USAddressLine2>
              <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/address/secondaryStreet,1,64)"/>
            </USAddressLine2>
          </xsl:if>
          <xsl:if test="$carrierBillingInfo/responsibleParty/address/city/text()">
            <USAddressCityName>
              <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/address/city,1,30)"/>
            </USAddressCityName>
          </xsl:if>
          <xsl:if test="$carrierBillingInfo/responsibleParty/address/state/text()">
            <CountrySubCode>
              <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/address/state,1,3)"/>
            </CountrySubCode>
          </xsl:if>
          <xsl:if test="$carrierBillingInfo/responsibleParty/address/country/text()">
            <USAddressCountryCode>
              <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/address/country,1,5)"/>
            </USAddressCountryCode>
          </xsl:if>
          <xsl:if test="$carrierBillingInfo/responsibleParty/address/postalCode/text()">
            <ZipCode>
              <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/address/postalCode, 1, 5)"/>
            </ZipCode>
            <xsl:if test="string-length($carrierBillingInfo/responsibleParty/address/postalCode/text()) > 6">
              <ExtendedZipCode>
                <xsl:value-of select="substring($carrierBillingInfo/responsibleParty/address/postalCode, 7)"/>
              </ExtendedZipCode>
            </xsl:if>
          </xsl:if>
          <xsl:variable name="fullPhoneNumber">
            <xsl:call-template name="findPhoneNumber">
              <xsl:with-param name="memberPersonalIdentification" select="$bse/memberPersonalIdentification"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="areaCode">
            <xsl:call-template name="areaCode">
              <xsl:with-param name="fullPhoneNumber" select="$fullPhoneNumber"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="phoneNumber">
            <xsl:call-template name="phoneNumber">
              <xsl:with-param name="fullPhoneNumber" select="$fullPhoneNumber"/>
              <xsl:with-param name="areaCode" select="$areaCode"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="extension">
            <xsl:call-template name="extension">
              <xsl:with-param name="fullPhoneNumber" select="$fullPhoneNumber"/>
              <xsl:with-param name="phoneNumber" select="$phoneNumber"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="string-length($areaCode) > 0">
            <USTelephoneAreaCode>
              <xsl:value-of select="$areaCode"/>
            </USTelephoneAreaCode>
          </xsl:if>
          <xsl:if test="string-length($phoneNumber) > 0">
            <USTelephoneNumber>
              <xsl:value-of select="translate($phoneNumber,'-','')"/>
            </USTelephoneNumber>
          </xsl:if>
          <xsl:if test="string-length($extension) > 0">
            <TelephoneExtension>
              <xsl:value-of select="substring($extension,1,4)"/>
            </TelephoneExtension>
          </xsl:if>
          <BillEmailPrefix>BILLING</BillEmailPrefix>
          <BillEmailSuffix>AETNA.COM</BillEmailSuffix>
        </xsl:if>
        <xsl:if test="($memberBenefitInfo/coverageDates and string-length($newBillPackage) > 0) or (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
          <RenewalDay>
            <xsl:choose>
              <xsl:when test="string-length($memberBenefitInfo/coverageDates/originalEffectiveDate/day) = 1">
                <xsl:value-of select="concat('0',$memberBenefitInfo/coverageDates/originalEffectiveDate/day)"/>
              </xsl:when>
              <xsl:when test="$memberBenefitInfo/coverageDates/originalEffectiveDate/day">
                <xsl:value-of select="$memberBenefitInfo/coverageDates/originalEffectiveDate/day"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring($memberBenefitInfo/coverageDates/originalEffectiveDate,9,2)"/>
              </xsl:otherwise>
            </xsl:choose>
          </RenewalDay>
          <BillFrequencyCode>MNT</BillFrequencyCode>
        </xsl:if>
        <xsl:if test="(($bse/transaction/memberTransactionTypes/text() = 'ADD_OR_UPDATE_PAYMENT_METHOD' or string-length($newBillPackage) > 0) and
                       ($memberBenefitInfo/initialPayment/Payment or $memberBenefitInfo/recurringPayment/Payment or $billInformation/billPaymentMethod)) or
                       ((string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE') and
                       ($memberBenefitInfo/initialPayment/Payment or $memberBenefitInfo/recurringPayment/Payment or $billInformation/billPaymentMethod))">
          <BillPaymentMethod>
            <xsl:choose>
              <xsl:when test="$memberBenefitInfo/recurringPayment/Payment/CreditCard or $billInformation/billPaymentMethod = 'RECURRING_CREDIT_CARD'">
                <xsl:value-of select="'RCC'"/>
              </xsl:when>
              <xsl:when test="$memberBenefitInfo/recurringPayment/Payment/ACH or $billInformation/billPaymentMethod = 'RECURRING_EFT'">
                <xsl:value-of select="'RFT'"/>
              </xsl:when>
              <xsl:when test="$memberBenefitInfo/initialPayment/Payment/CreditCard or $billInformation/billPaymentMethod = 'NON_RECURRING_CREDIT_CARD'">
                <xsl:value-of select="'NCC'"/>
              </xsl:when>
              <xsl:when test="($memberBenefitInfo/initialPayment/Payment/ACH or $billInformation/billPaymentMethod = 'NON_RECURRING_EFT') and
                               not($memberBenefitInfo/initialPayment/Payment/Check and ($memberBenefitInfo/initialPayment/Payment/Check/NameOnCheck/text() or $memberBenefitInfo/initialPayment/Payment/Check/CheckNumber/text()))">
                <xsl:value-of select="'NFT'"/>
              </xsl:when>
              <xsl:when test="($memberBenefitInfo/initialPayment/Payment/Check and
                              ($memberBenefitInfo/initialPayment/Payment/Check/NameOnCheck/text() or $memberBenefitInfo/initialPayment/Payment/Check/CheckNumber/text()))or $billInformation/billPaymentMethod = 'CHECK'">
                <xsl:value-of select="'CHK'"/>
              </xsl:when>
            </xsl:choose>
          </BillPaymentMethod>
        </xsl:if>
        <xsl:if test="string-length($newBillPackage) > 0 or (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
          <xsl:choose>
            <xsl:when test="$billInformation/billAction = 'SUPPRESS_BILLS'">
              <SuppressBillOrPrintInd>SBB</SuppressBillOrPrintInd>
            </xsl:when>
            <xsl:when test="$billInformation/billAction = 'PRINT_BILLS'">
              <SuppressBillOrPrintInd>SBP</SuppressBillOrPrintInd>
            </xsl:when>
            <xsl:when test="$billInformation/billAction = 'REVERSAL'">
              <!-- todo what to do with reversal? -->
              <SuppressBillOrPrintInd>RVS</SuppressBillOrPrintInd>
            </xsl:when>
          </xsl:choose>
        </xsl:if>
      </xsl:if>
    </BillPackage>
  </xsl:template>

  <xsl:template name="isNewBillPackage">
    <xsl:param name="bse"/>
    <xsl:if test="$bse/transaction/memberTransactionTypes/text() = 'ADD_SUBSCRIBER' or $bse/transaction/memberTransactionTypes/text() = 'NEW_ENROLLMENT'">true</xsl:if>
  </xsl:template>

  <xsl:template name="isChangeBillPackage">
    <xsl:param name="bse"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'UPDATE_SUBSCRIBER'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CARRIER_BILLING_INFORMATION'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_TYPE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'UPDATE_APPLICATION_ID'">true</xsl:when>
      <xsl:when test="$bse/transaction/billingTransactionTypes/text()">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="findPhoneNumber">
    <xsl:param name="memberPersonalIdentification"/>
    <xsl:variable name="unformattedPhoneNumber">
      <xsl:choose>
        <xsl:when test="$memberPersonalIdentification/homePhoneNumber[string-length(text()) > 0]">
          <xsl:value-of select="$memberPersonalIdentification/homePhoneNumber"/>
        </xsl:when>
        <xsl:when test="$memberPersonalIdentification/mobilePhoneNumber[string-length(text()) > 0]">
          <xsl:value-of select="$memberPersonalIdentification/mobilePhoneNumber"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$memberPersonalIdentification/alternatePhoneNumber"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="phoneNumberDigitsOnly">
      <xsl:value-of select="translate($unformattedPhoneNumber, '-', '')"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="starts-with($unformattedPhoneNumber, '1-')">
        <xsl:value-of select="substring($unformattedPhoneNumber, 3)"/>
      </xsl:when>
      <xsl:when test="starts-with($unformattedPhoneNumber, '1') and string-length($phoneNumberDigitsOnly) != 7 and string-length($phoneNumberDigitsOnly) != 10">
        <xsl:value-of select="substring($unformattedPhoneNumber, 2)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$unformattedPhoneNumber"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="areaCode">
    <xsl:param name="fullPhoneNumber"/>
    <xsl:variable name="part1">
      <xsl:choose>
        <xsl:when test="contains($fullPhoneNumber, '-')">
          <xsl:value-of select="substring-before($fullPhoneNumber, '-')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$fullPhoneNumber"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="remainder">
      <xsl:choose>
        <xsl:when test="starts-with(substring($fullPhoneNumber, string-length($part1) + 1), '-')">
          <xsl:value-of select="substring($fullPhoneNumber, string-length($part1) + 2)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring($fullPhoneNumber, string-length($part1) + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="part2">
      <xsl:choose>
        <xsl:when test="contains($remainder, '-')">
          <xsl:value-of select="substring-before($remainder, '-')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$remainder"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($part1) = 10">
        <xsl:value-of select="substring($part1,1,3)"/>
      </xsl:when>
      <xsl:when test="string-length($part1) = 3 and (string-length($part2) = 3 or string-length($part2) = 7)">
        <xsl:value-of select="$part1"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="phoneNumber">
    <xsl:param name="fullPhoneNumber"/>
    <xsl:param name="areaCode"/>
    <xsl:variable name="remainder">
      <xsl:choose>
        <xsl:when test="string-length($areaCode) > 0 and starts-with(substring-after($fullPhoneNumber, $areaCode), '-')">
          <xsl:value-of select="substring-after($fullPhoneNumber, concat($areaCode,'-'))"/>
        </xsl:when>
        <xsl:when test="string-length($areaCode) > 0">
          <xsl:value-of select="substring-after($fullPhoneNumber, $areaCode)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$fullPhoneNumber"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="phoneNumberSize">
      <xsl:choose>
        <xsl:when test="contains(substring($remainder, 1, 5), '-')">8</xsl:when>
        <xsl:otherwise>7</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="substring($remainder, 1, $phoneNumberSize)"/>
  </xsl:template>

  <xsl:template name="extension">
    <xsl:param name="fullPhoneNumber"/>
    <xsl:param name="phoneNumber"/>
    <xsl:choose>
      <xsl:when test="string-length($phoneNumber) > 0 and starts-with(substring-after($fullPhoneNumber, $phoneNumber), '-')">
        <xsl:value-of select="substring-after($fullPhoneNumber, concat($phoneNumber,'-'))"/>
      </xsl:when>
      <xsl:when test="string-length($phoneNumber) > 0">
        <xsl:value-of select="substring-after($fullPhoneNumber, $phoneNumber)"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="processSubscriber">
    <xsl:param name="bse"/>
    <xsl:param name="subscriberMemberReferenceId"/>
    <xsl:param name="planName"/>
    <xsl:variable name="subMemberId" select="$bse//*[name() = 'memberIdentification' and @referenceId = $subscriberMemberReferenceId]"/>
    <xsl:variable name="subMemberPersonalId" select="$bse//*[name() = 'memberPersonalIdentification' and (@referenceId = $subscriberMemberReferenceId or @referenceId = $subMemberId/BenefitfocusPersonId)]"/>
    <xsl:variable name="benefit" select="$bse/memberBenefit[subscriber/memberIdentificationReferenceId/text() = $subscriberMemberReferenceId and planName/text() = $planName and productType != 'RIDER']"/>

    <xsl:variable name="newSubscriber">
      <xsl:call-template name="isNewSubscriber">
        <xsl:with-param name="bse" select="$bse"/>
        <xsl:with-param name="subscriberMemberReferenceId" select="$subscriberMemberReferenceId"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="changeSubscriber">
      <xsl:call-template name="isChangeSubscriber">
        <xsl:with-param name="bse" select="$bse"/>
        <xsl:with-param name="benefit" select="$benefit"/>
        <xsl:with-param name="subscriberMemberReferenceId" select="$subscriberMemberReferenceId"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="generalDependentChange">
      <xsl:call-template name="isGeneralChangeDependent">
        <xsl:with-param name="bse" select="$bse"/>
        <xsl:with-param name="benefit" select="$benefit"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="changeBillPackage">
      <xsl:call-template name="isChangeBillPackage">
        <xsl:with-param name="bse" select="$bse"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="string-length($newSubscriber) > 0 or string-length($changeSubscriber) > 0 or string-length($generalDependentChange) > 0">
      <MemberInfo>
        <xsl:if test="string-length($newSubscriber) > 0 or string-length($changeSubscriber) > 0 or string-length($generalDependentChange) > 0">
          <SubscriberRecordType>
            <xsl:choose>
              <xsl:when test="string-length($newSubscriber) > 0">BSN</xsl:when>
              <xsl:when test="string-length($changeSubscriber) > 0 or string-length($generalDependentChange) > 0" >BSM</xsl:when>
            </xsl:choose>
          </SubscriberRecordType>
          <xsl:variable name="memberId">
            <xsl:call-template name="processMemberId">
              <xsl:with-param name="personCarrierIdentification" select="$subMemberId"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="hideSubscriberID">
            <xsl:call-template name="hideSubscriberIndividualID">
              <xsl:with-param name="bse" select="$bse"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="string-length($memberId) > 0 and not(normalize-space($hideSubscriberID) = 'true')">
            <SubscriberIndividualID>
              <xsl:value-of select="substring($memberId,0,16)"/>
            </SubscriberIndividualID>
          </xsl:if>
          <xsl:variable name="hideSubscriberSSNAndEffectiveDateValue">
            <xsl:call-template name="hideSubscriberSSNAndEffectiveDate">
              <xsl:with-param name="bse" select="$bse"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="not(normalize-space($hideSubscriberSSNAndEffectiveDateValue) = 'true')">
            <xsl:if test="$subMemberPersonalId/ssn/text()">
              <SubscriberSSN>
                <xsl:value-of select="translate($subMemberPersonalId/ssn,'-','')"/>
              </SubscriberSSN>
            </xsl:if>
            <SubscriberEffectiveDate>
              <xsl:call-template name="translateDate">
                <xsl:with-param name="rawDate" select="$benefit/coverageDates/effectiveDate"/>
              </xsl:call-template>
            </SubscriberEffectiveDate>
          </xsl:if>
          <xsl:variable name="hideSubscriberRelationCd">
            <xsl:call-template name="hideSubscriberRelationCd">
              <xsl:with-param name="bse" select="$bse"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="not(normalize-space($hideSubscriberRelationCd) = 'true')">
            <SubscriberFamilyRelationCd>
              <xsl:choose>
                <xsl:when test="$subscriberMemberReferenceId = $bse/memberIdentification/@referenceId">001</xsl:when>
                <xsl:otherwise>002</xsl:otherwise>
              </xsl:choose>
            </SubscriberFamilyRelationCd>
            <SubscriberFirstName>
              <xsl:value-of select="substring($subMemberPersonalId/personName/firstName,1,25)"/>
            </SubscriberFirstName>
            <xsl:if test="$subMemberPersonalId/personName/middleName/text()">
              <SubscriberMiddleInitial>
                <xsl:value-of select="substring($subMemberPersonalId/personName/middleName, 1,1)"/>
              </SubscriberMiddleInitial>
            </xsl:if>
            <SubscriberLastName>
              <xsl:value-of select="substring($subMemberPersonalId/personName/lastName,1,25)"/>
            </SubscriberLastName>
          </xsl:if>
          <xsl:variable name="hideSubscriberDateOfBirthValue">
            <xsl:call-template name="hideSubscriberDateOfBirth">
              <xsl:with-param name="bse" select="$bse"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="not(normalize-space($hideSubscriberDateOfBirthValue) = 'true')">
            <SubscriberDateOfBirth>
              <xsl:call-template name="translateDate">
                <xsl:with-param name="rawDate" select="$subMemberPersonalId/birthDate"/>
              </xsl:call-template>
            </SubscriberDateOfBirth>
          </xsl:if>
          <xsl:if test="not(normalize-space($hideSubscriberRelationCd) = 'true')">
            <SubscriberSexCode>
              <xsl:choose>
                <xsl:when test="$subMemberPersonalId/gender = 'MALE'">M</xsl:when>
                <xsl:when test="$subMemberPersonalId/gender = 'FEMALE'">F</xsl:when>
              </xsl:choose>
            </SubscriberSexCode>
          </xsl:if>
          <xsl:variable name="hideSubscriberPlanNameValue">
            <xsl:call-template name="hideSubscriberPlanName">
              <xsl:with-param name="bse" select="$bse"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="not(normalize-space($hideSubscriberPlanNameValue) = 'true')">
            <SubscriberPlanName>
              <!--todo confirm this is the right element to get this value from-->
              <xsl:value-of select="substring($benefit/planName,1,100)"/>
            </SubscriberPlanName>
          </xsl:if>
          <xsl:if test="not(normalize-space($hideSubscriberRelationCd) = 'true')">
            <SubscriberZipCode>
              <xsl:value-of select="substring($subMemberPersonalId/address/postalCode, 1, 5)"/>
            </SubscriberZipCode>
            <xsl:if test="string-length($subMemberPersonalId/address/postalCode/text()) > 6">
              <SubscriberExtdZipCode>
                <xsl:value-of select="substring($subMemberPersonalId/address/postalCode, 7)"/>
              </SubscriberExtdZipCode>
            </xsl:if>
            <xsl:if test="$benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'HIPAA_IND']/value">
              <SubscriberHIPAAInd>
                <xsl:choose>
                  <xsl:when test="substring($benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'HIPAA_IND']/value,1,1) = 'T'">
                    <xsl:value-of select="'Y'"/>
                  </xsl:when>
                  <xsl:when test="substring($benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'HIPAA_IND']/value,1,1) = 'F'">
                    <xsl:value-of select="'N'"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="substring($benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'HIPAA_IND']/value,1,1)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </SubscriberHIPAAInd>
            </xsl:if>
            <HIPAACntrctTierCode>
              <xsl:choose>
                <xsl:when test="$benefit/coverageLevelName/text() = 'EmployeeOnly' or $benefit/coverageLevelName/text() = 'Subscriber'">SUB</xsl:when>
                <xsl:when test="$benefit/coverageLevelName/text() = 'EmployeeAndSpouse' or $benefit/coverageLevelName/text() = 'Subscriber + Spouse'">SUBS</xsl:when>
                <xsl:when test="$benefit/coverageLevelName/text() = 'Family' or $benefit/coverageLevelName/text() = 'Subscriber + Family'">SUBF</xsl:when>
                <xsl:when test="$benefit/coverageLevelName/text() = 'EmployeeAndChildren' or $benefit/coverageLevelName/text() = 'Subscriber + Children'">SUBC</xsl:when>
                <xsl:when test="$benefit/coverageLevelName/text() = 'EmployeeAndOneDependent' or $benefit/coverageLevelName/text() = 'Subscriber + 1 dependent'">SUBD1</xsl:when>
                <xsl:when test="$benefit/coverageLevelName/text() = 'EmployeeAndTwoDependents' or $benefit/coverageLevelName/text() = 'Subscriber + 2 dependent'">SUBD2</xsl:when>
                <xsl:when test="$benefit/coverageLevelName/text() = 'EmployeeAndSpouseOrDomesticPartner' or $benefit/coverageLevelName/text() = 'Subscriber + Spouse/Domestic Partner'">SUBSPD</xsl:when>
                <xsl:when test="$benefit/coverageLevelName/text() = 'EmployeeAndSpouseOrCivilUnionPartner' or $benefit/coverageLevelName/text() = 'Subscriber + Spouse/Civil Union Partner'">SUBSCU</xsl:when>
              </xsl:choose>
            </HIPAACntrctTierCode>
            <RateMethodologyCd>NEW</RateMethodologyCd>
          </xsl:if>
          <xsl:variable name="hideSubscriberRateInfoValue">
            <xsl:call-template name="hideSubscriberRateInfo">
              <xsl:with-param name="bse" select="$bse"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="not(normalize-space($hideSubscriberRateInfoValue) = 'true')">
            <RateGuaranteeBeginDate>
              <xsl:choose>
                <xsl:when test="$benefit/planRate/effectiveDate/text()">
                  <xsl:call-template name="translateDate">
                    <xsl:with-param name="rawDate" select="$benefit/planRate/effectiveDate"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="translateDate">
                    <xsl:with-param name="rawDate" select="$benefit/coverageDates/originalEffectiveDate"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </RateGuaranteeBeginDate>
            <xsl:if test="$benefit/planRate/rateGuaranteeExpirationDate/text()">
              <RateGuaranteeEndDate>
                <xsl:call-template name="translateDate">
                  <xsl:with-param name="rawDate" select="$benefit/planRate/rateGuaranteeExpirationDate"/>
                </xsl:call-template>
              </RateGuaranteeEndDate>
            </xsl:if>
          </xsl:if>
          <xsl:if test="(string-length($newSubscriber) > 0 or string-length($changeSubscriber) > 0) and
                string-length($benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'FINAL_RATEUP_FACTOR']/value) > 0 and
                ($bse/transaction[memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_EMPLOYEE'] or $bse/transaction[memberTransactionTypes/text() = 'ADD_SUBSCRIBER']
                or $bse/transaction[memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE'])">
            <SubscriberFinalRateUpFactor>
              <xsl:value-of select="substring($benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'FINAL_RATEUP_FACTOR']/value,1,10)"/>
            </SubscriberFinalRateUpFactor>
          </xsl:if>
          <xsl:if test="(string-length($newSubscriber) > 0 or string-length($changeSubscriber) > 0) and
                string-length($benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'INDIVIDUAL_RATEUP_FACTOR']/value) > 0 and
                ($bse/transaction[memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_EMPLOYEE'] or $bse/transaction[memberTransactionTypes/text() = 'ADD_SUBSCRIBER']
                or $bse/transaction[memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE'])">
            <SubscriberIndRateUpFactor>
              <xsl:value-of select="substring($benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'INDIVIDUAL_RATEUP_FACTOR']/value,1,10)"/>
            </SubscriberIndRateUpFactor>
          </xsl:if>
          <xsl:if test="string-length($newSubscriber) > 0 or (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
            <xsl:call-template name="processAnniversaryDate">
              <xsl:with-param name="origEffDate" select="$benefit/coverageDates/originalEffectiveDate"/>
            </xsl:call-template>
          </xsl:if>

          <!-- we don't have all the requirements for what to render here yet so commenting out until these are finalized
          <UBMIndicator>

          </UBMIndicator>
          <Standalonedentalind>

          </Standalonedentalind>
          -->

          <xsl:if test="$benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'CANCEL_REASON']/value">
            <TermReasonCode>
              <xsl:value-of select="substring($benefit/carrierDefinedFields/carrierDefinedField[type/text() = 'CANCEL_REASON']/value,1,50)"/>
            </TermReasonCode>
          </xsl:if>
        </xsl:if>

        <xsl:if test="string-length($benefit/subscriber/memberBenefitIdentification/altMemberBenefitId) > 0">
          <Cumbid>
            <xsl:value-of select="substring($benefit/subscriber/memberBenefitIdentification/altMemberBenefitId,1,13)"/>
          </Cumbid>
        </xsl:if>
        <xsl:if test="(string-length($newSubscriber) > 0 or string-length($changeSubscriber) > 0)">
          <Subscriberstatecode>
            <xsl:value-of select="$subMemberPersonalId/address/state"/>
          </Subscriberstatecode>
        </xsl:if>

        <xsl:for-each select="$benefit/familyMember[not(memberIdentificationReferenceId/text() = $subscriberMemberReferenceId)]">
          <xsl:call-template name="processDependent">
            <xsl:with-param name="bse" select="$bse"/>
            <xsl:with-param name="subscriberMemberReferenceId" select="$subscriberMemberReferenceId"/>
            <xsl:with-param name="dependentMemberReferenceId" select="memberIdentificationReferenceId"/>
            <xsl:with-param name="subBenefit" select="$benefit"/>
          </xsl:call-template>
        </xsl:for-each>
      </MemberInfo>
    </xsl:if>
  </xsl:template>

  <xsl:template name="isNewSubscriber">
    <xsl:param name="bse"/>
    <xsl:param name="subscriberMemberReferenceId"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $subscriberMemberReferenceId]/memberTransactionTypes/text() = 'ADD_SUBSCRIBER'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="isChangeSubscriber">
    <xsl:param name="bse"/>
    <xsl:param name="benefit"/>
    <xsl:param name="subscriberMemberReferenceId"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $subscriberMemberReferenceId]/memberTransactionTypes/text() = 'UPDATE_SUBSCRIBER'">true</xsl:when>
      <xsl:when test="$benefit/subscriber/@referenceId and $bse/transaction[transactionObjectReferenceId = $benefit/subscriber/@referenceId]/memberTransactionTypes/text() = 'CANCEL_SUBSCRIBER'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId]/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_EMPLOYEE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId]/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_EMPLOYEE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId]/memberTransactionTypes/text() = 'PLAN_RATE_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId]/memberTransactionTypes/text() = 'PLAN_RATE_GUARANTEE_EXPIRATION_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId]/memberTransactionTypes/text() = 'UPDATE_BENEFIT_PLAN'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId and string-length(childObjectReferenceIds/text()) = 0]/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId and string-length(childObjectReferenceIds/text()) = 0]/memberTransactionTypes/text() = 'BENEFIT_EFFECTIVE_DATE'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="isGeneralChangeDependent">
    <xsl:param name="bse"/>
    <xsl:param name="benefit"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId]/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/@referenceId]/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_ADOPTEE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_NEW_BORN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="processMemberId">
    <xsl:param name="personCarrierIdentification"/>
    <xsl:choose>
      <xsl:when test="$personCarrierIdentification/personCarrierIdentification/memberId/text()">
        <xsl:value-of select="$personCarrierIdentification/personCarrierIdentification/memberId"/>
      </xsl:when>
      <xsl:when test="$personCarrierIdentification/personCarrierIdentification/alternateMemberId/text()">
        <xsl:value-of select="$personCarrierIdentification/personCarrierIdentification/alternateMemberId"/>
      </xsl:when>
      <xsl:when test="$personCarrierIdentification/personCarrierIdentification/alternateMemberId2/text()">
        <xsl:value-of select="$personCarrierIdentification/personCarrierIdentification/alternateMemberId2"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="processAnniversaryDate">
    <xsl:param name="origEffDate"/>
    <xsl:variable name="formattedDate">
      <xsl:call-template name="translateDate">
        <xsl:with-param name="rawDate" select="$origEffDate"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="monthDate" select="substring($formattedDate, 6, 5)"/>
    <xsl:variable name="year" select="number(substring($formattedDate, 1, 4)) + 1"/>
    <AnniversaryDate>
      <xsl:value-of select="concat($year, '-', $monthDate)"/>
    </AnniversaryDate>
  </xsl:template>

  <xsl:template name="processDependent">
    <xsl:param name="bse"/>
    <xsl:param name="subscriberMemberReferenceId"/>
    <xsl:param name="dependentMemberReferenceId"/>
    <xsl:param name="subBenefit"/>
    <xsl:variable name="subMemberId" select="$bse//*[name() = 'memberIdentification' and @referenceId = $subscriberMemberReferenceId]"/>
    <xsl:variable name="subMemberPersonalId" select="$bse//*[name() = 'memberPersonalIdentification' and (@referenceId = $subscriberMemberReferenceId or @referenceId = $subMemberId/BenefitfocusPersonId)]"/>
    <xsl:variable name="depMemberId" select="$bse//*[name() = 'memberIdentification' and @referenceId = $dependentMemberReferenceId]"/>
    <xsl:variable name="depMemberPersonalId" select="$bse//*[name() = 'memberPersonalIdentification' and (@referenceId = $dependentMemberReferenceId or @referenceId = $depMemberId/BenefitfocusPersonId)]"/>
    <xsl:variable name="depBenefit" select="$subBenefit/familyMember[memberIdentificationReferenceId/text() = $dependentMemberReferenceId]"/>
    <xsl:variable name="newDependent">
      <xsl:call-template name="isNewDependent">
        <xsl:with-param name="bse" select="$bse"/>
        <xsl:with-param name="subscriberMemberReferenceId" select="$subscriberMemberReferenceId"/>
        <xsl:with-param name="dependentMemberReferenceId" select="$dependentMemberReferenceId"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="changeDependent">
      <xsl:call-template name="isChangeDependent">
        <xsl:with-param name="bse" select="$bse"/>
        <xsl:with-param name="dependentMemberReferenceId" select="$dependentMemberReferenceId"/>
        <xsl:with-param name="benefit" select="$depBenefit"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="changeBillPackage">
      <xsl:call-template name="isChangeBillPackage">
        <xsl:with-param name="bse" select="$bse"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="(string-length($newDependent) > 0 or string-length($changeDependent) > 0)">
      <DependentInfo>
        <DependentRecordType>
          <xsl:choose>
            <xsl:when test="string-length($newDependent) > 0">BDN</xsl:when>
            <xsl:when test="string-length($changeDependent) > 0">BDM</xsl:when>
          </xsl:choose>
        </DependentRecordType>
        <xsl:variable name="subId">
          <xsl:call-template name="processMemberId">
            <xsl:with-param name="personCarrierIdentification" select="$subMemberId"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="string-length($subId) > 0">
          <SubsIndividualID>
            <xsl:value-of select="substring($subId,1,16)"/>
          </SubsIndividualID>
        </xsl:if>
        <SubsSSN>
          <xsl:value-of select="translate($subMemberPersonalId/ssn,'-','')"/>
        </SubsSSN>
        <xsl:variable name="depId">
          <xsl:call-template name="processMemberId">
            <xsl:with-param name="personCarrierIdentification" select="$depMemberId"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="string-length($depId) > 0">
          <DependentIndividualID>
            <xsl:value-of select="$depId"/>
          </DependentIndividualID>
        </xsl:if>
        <DependentEffectiveDate>
          <xsl:call-template name="translateDate">
            <xsl:with-param name="rawDate" select="$depBenefit/coverageDates/effectiveDate"/>
          </xsl:call-template>
        </DependentEffectiveDate>
        <DependentDateOfBirth>
          <xsl:call-template name="translateDate">
            <xsl:with-param name="rawDate" select="$depMemberPersonalId/birthDate"/>
          </xsl:call-template>
        </DependentDateOfBirth>
        <xsl:if test="$depMemberPersonalId/ssn">
          <DependentSSN>
            <xsl:value-of select="translate($depMemberPersonalId/ssn,'-','')"/>
          </DependentSSN>
        </xsl:if>
        <xsl:if test="($depMemberPersonalId/gender and string-length($newDependent) > 0) or (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
          <DependentSexCode>
            <xsl:choose>
              <xsl:when test="$depMemberPersonalId/gender = 'MALE'">M</xsl:when>
              <xsl:when test="$depMemberPersonalId/gender = 'FEMALE'">F</xsl:when>
            </xsl:choose>
          </DependentSexCode>
        </xsl:if>
        <xsl:if test="string-length($depBenefit/carrierDefinedFields/carrierDefinedField[type/text() = 'INDIVIDUAL_RATEUP_FACTOR']/value) > 0 and
                      ((string-length($newDependent) > 0 or $bse/transaction[childObjectReferenceIds/childObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_DEPENDENT') or
                       (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE'))">
          <DependentRateupFactor>
            <xsl:value-of select="substring($depBenefit/carrierDefinedFields/carrierDefinedField[type/text() = 'INDIVIDUAL_RATEUP_FACTOR']/value,1,10)"/>
          </DependentRateupFactor>
        </xsl:if>
        <xsl:if test="string-length($depBenefit/carrierDefinedFields/carrierDefinedField[type/text() = 'FINAL_RATEUP_FACTOR']/value) > 0 and
                      ((string-length($newDependent) > 0 or $bse/transaction[childObjectReferenceIds/childObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_DEPENDENT') or
                       (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE'))">
          <DependentFinalRateUpFactor>
            <xsl:value-of select="substring($depBenefit/carrierDefinedFields/carrierDefinedField[type/text() = 'FINAL_RATEUP_FACTOR']/value,1,10)"/>
          </DependentFinalRateUpFactor>
        </xsl:if>
        <xsl:if test="$depBenefit/adoptionDate/text() and $bse/transaction[transactionObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes = 'ADD_ADOPTEE'">
          <AdopteeIndicator>Y</AdopteeIndicator>
        </xsl:if>
        <xsl:if test="$bse/transaction[transactionObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes = 'ADD_NEW_BORN'">
          <NewBornIndicator>Y</NewBornIndicator>
        </xsl:if>
        <xsl:variable name="newSubscriber">
          <xsl:call-template name="isNewSubscriber">
            <xsl:with-param name="bse" select="$bse"/>
            <xsl:with-param name="subscriberMemberReferenceId" select="$subscriberMemberReferenceId"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="transactionType" select="$bse/transaction[transactionObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes"/>
        <xsl:variable name="childTransactionType" select="$bse/transaction[childObjectReferenceIds/childObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes"/>

        <xsl:if test="string-length($newSubscriber) > 0 or
                string-length($newDependent) > 0 or
                $childTransactionType/text() = 'CHANGE_DEPENDENT_FAMILY_CODE' or
                $transactionType/text() = 'CHANGE_DEPENDENT_FAMILY_CODE' or
                $bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE' or
                (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
          <DependentFamilyCode>
            <xsl:choose>
              <xsl:when test="$depBenefit/relationship/text() = 'SPOUSE'">001</xsl:when>
              <xsl:otherwise>002</xsl:otherwise>
            </xsl:choose>
          </DependentFamilyCode>
        </xsl:if>
        <xsl:if test="$depBenefit/carrierDefinedFields/carrierDefinedField[type/text() = 'HIPAA_IND']/value and string-length($newDependent) > 0 or
                      (string-length($changeBillPackage) > 0 and $bse/transaction/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE')">
          <xsl:if test="$depBenefit/carrierDefinedFields/carrierDefinedField[type/text() = 'HIPAA_IND']">
            <DependentHIPAAIndicator>
              <xsl:value-of select="substring($depBenefit/carrierDefinedFields/carrierDefinedField[type/text() = 'HIPAA_IND']/value,1,1)"/>
            </DependentHIPAAIndicator>
          </xsl:if>
        </xsl:if>
      </DependentInfo>
    </xsl:if>
  </xsl:template>

  <xsl:template name="isNewDependent">
    <xsl:param name="bse"/>
    <xsl:param name="subscriberMemberReferenceId"/>
    <xsl:param name="dependentMemberReferenceId"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $subscriberMemberReferenceId]/memberTransactionTypes/text() = 'ADD_SUBSCRIBER'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'ADD_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'ADD_ADOPTEE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'ADD_NEW_BORN'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="isChangeDependent">
    <xsl:param name="bse"/>
    <xsl:param name="dependentMemberReferenceId"/>
    <xsl:param name="benefit"/>
    <xsl:choose>
      <xsl:when test="$bse//memberTransactionTypes/text() = 'UPDATE_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[childObjectReferenceIds/childObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[childObjectReferenceIds/childObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[childObjectReferenceIds/childObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $benefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'BENEFIT_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction[childObjectReferenceIds/childObjectReferenceId = $dependentMemberReferenceId]/memberTransactionTypes/text() = 'BENEFIT_ORIGINAL_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="hideSubscriberIndividualID">
    <xsl:param name="bse"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_ADOPTEE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_NEW_BORN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'UPDATE_BENEFIT_PLAN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BENEFIT_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_OR_UPDATE_PAYMENT_METHOD'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="hideSubscriberSSNAndEffectiveDate">
    <xsl:param name="bse"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_ADOPTEE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_NEW_BORN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BENEFIT_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_OR_UPDATE_PAYMENT_METHOD'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="hideSubscriberRelationCd">
    <xsl:param name="bse"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_ADOPTEE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_NEW_BORN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'UPDATE_BENEFIT_PLAN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'PLAN_RATE_GUARANTEE_EXPIRATION_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BENEFIT_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_OR_UPDATE_PAYMENT_METHOD'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CANCEL_SUBSCRIBER'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="hideSubscriberRateInfo">
    <xsl:param name="bse"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_ADOPTEE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_NEW_BORN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'UPDATE_BENEFIT_PLAN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BENEFIT_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_OR_UPDATE_PAYMENT_METHOD'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CANCEL_SUBSCRIBER'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="hideSubscriberPlanName">
    <xsl:param name="bse"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_ADOPTEE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_NEW_BORN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BENEFIT_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'FINAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'INDIVIDUAL_RATEUP_FACTOR_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_OR_UPDATE_PAYMENT_METHOD'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CANCEL_SUBSCRIBER'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="hideSubscriberDateOfBirth">
    <xsl:param name="bse"/>
    <xsl:choose>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_DEPENDENT'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_ADOPTEE'">true</xsl:when>
      <xsl:when test="$bse/transaction[transactionObjectReferenceId = $bse/memberbenefit/familyMember/memberIdentificationReferenceId]/memberTransactionTypes/text() = 'ADD_NEW_BORN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'UPDATE_BENEFIT_PLAN'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BENEFIT_EFFECTIVE_DATE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'CHANGE_DEPENDENT_FAMILY_CODE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'ADD_OR_UPDATE_PAYMENT_METHOD'">true</xsl:when>
      <xsl:when test="$bse/transaction/memberTransactionTypes/text() = 'BILLING_CYCLE_DATE_CHANGE'">true</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="processSpecialRequest">
    <xsl:param name="bse"/>
    <xsl:variable name="billInformation" select="$bse/billInformation"/>

    <SpecialRequestInfo>
      <SpecialRequestRecordtype>SRQ</SpecialRequestRecordtype>
      <xsl:choose>
        <xsl:when test="$billInformation/billAction = 'SUPPRESS_BILLS'">
          <SRQIndType>SBB</SRQIndType>
        </xsl:when>
        <xsl:when test="$billInformation/billAction = 'PRINT_BILLS'">
          <SRQIndType>SBP</SRQIndType>
        </xsl:when>
      </xsl:choose>
      <SRQLineOfBusiness>IVL</SRQLineOfBusiness>
      <SRQPostedDTS>
        <xsl:call-template name="translateDateTime">
          <xsl:with-param name="rawDate" select="$bse/eventDate"/>
          <xsl:with-param name="formatted" select="true()"/>
        </xsl:call-template>
      </SRQPostedDTS>
      <EffectiveDate>
        <xsl:call-template name="translateDate">
          <xsl:with-param name="rawDate" select="$billInformation/effectiveDate"/>
        </xsl:call-template>
      </EffectiveDate>
      <xsl:if test="$billInformation/expirationDate and not(starts-with($billInformation/expirationDate/text(), '9999'))">
        <ExpirationDate>
          <xsl:call-template name="translateDate">
            <xsl:with-param name="rawDate" select="$billInformation/expirationDate"/>
          </xsl:call-template>
        </ExpirationDate>
      </xsl:if>
      <xsl:if test="$billInformation/temporarySuppression/postalCodes">
        <ZipCodeParmText>
          <!--todo how to handle multiple values-->
          <xsl:value-of select="$billInformation/temporarySuppression/postalCodes"/>
        </ZipCodeParmText>
      </xsl:if>
      <xsl:if test="$billInformation/temporarySuppression/states">
        <StateCodeParmText>
          <!--todo how to handle multiple values-->
          <xsl:value-of select="$billInformation/temporarySuppression/states"/>
        </StateCodeParmText>
      </xsl:if>

      <!-- Still pending requirements for what goes into these fields and when we want to show them
      <BillingTypeParmText>

      </BillingTypeParmText>
      <SRQBillEmailPrefix>

      </SRQBillEmailPrefix>
      <SRQBillEmailSuffix>

      </SRQBillEmailSuffix>
      -->
    </SpecialRequestInfo>
  </xsl:template>

  <xsl:template name="processTrailer">
    <TrailerInfo>
      <TrailerRecordtype>999</TrailerRecordtype>
      <FamilyTransactionCounter>0</FamilyTransactionCounter>
      <SpecialRequestCounter>0</SpecialRequestCounter>
      <TotalTransactionCounter>0</TotalTransactionCounter>
    </TrailerInfo>
  </xsl:template>

  <xsl:template name="translateDate">
    <xsl:param name="rawDate"/>
    <xsl:choose>
      <xsl:when test="$rawDate/year and $rawDate/month and $rawDate/day">
        <xsl:variable name="month">
          <xsl:choose>
            <xsl:when test="string-length($rawDate/month) = 1">
              <xsl:value-of select="concat('0',$rawDate/month)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$rawDate/month"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="day">
          <xsl:choose>
            <xsl:when test="string-length($rawDate/day) = 1">
              <xsl:value-of select="concat('0',$rawDate/day)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$rawDate/day"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($rawDate/year, '-', $month, '-', $day)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring($rawDate, 1, 10)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="translateDateTime">
    <xsl:param name="rawDate"/>
    <xsl:param name="formatted"/>
    <xsl:variable name="date">
      <xsl:call-template name="translateDate">
        <xsl:with-param name="rawDate" select="$rawDate"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="rawTime">
      <xsl:choose>
        <xsl:when test="contains(substring-after($rawDate, 'T'), '-')">
          <xsl:call-template name="changeTimeDelimiter">
            <xsl:with-param name="string" select="substring-before(substring-after($rawDate, 'T'), '-')"/>
            <xsl:with-param name="oldDelimiter" select="':'"/>
            <xsl:with-param name="newDelimiter" select="'.'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="not(contains(substring-after($rawDate, 'T'), '-'))">
          <xsl:call-template name="changeTimeDelimiter">
            <xsl:with-param name="string" select="substring-after($rawDate, 'T')"/>
            <xsl:with-param name="oldDelimiter" select="':'"/>
            <xsl:with-param name="newDelimiter" select="'.'"/>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="hour">
      <xsl:choose>
        <xsl:when test="$rawDate/year">
          <xsl:choose>
            <xsl:when test="string-length($rawDate/hour) = 1">
              <xsl:value-of select="concat('0',$rawDate/hour)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$rawDate/hour"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'00'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="minute">
      <xsl:choose>
        <xsl:when test="$rawDate/minute">
          <xsl:choose>
            <xsl:when test="string-length($rawDate/minute) = 1">
              <xsl:value-of select="concat('0',$rawDate/minute)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$rawDate/minute"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'00'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="second">
      <xsl:choose>
        <xsl:when test="$rawDate/second">
          <xsl:choose>
            <xsl:when test="string-length($rawDate/second) = 1">
              <xsl:value-of select="concat('0',$rawDate/second)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$rawDate/second"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'00'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$formatted">
        <xsl:choose>
          <xsl:when test="$rawTime">
            <xsl:value-of select="concat($date, '-', $rawTime, '000')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($date, '-', $hour, '.', $minute, '.', $second, '.000000')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$rawTime">
            <xsl:value-of select="concat(translate($date,'-',''), $rawTime, '000')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat(translate($date,'-',''), $hour, $minute, $second, '000000')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="changeTimeDelimiter">
    <xsl:param name="string" />
    <xsl:param name="oldDelimiter" select="':'" />
    <xsl:param name="newDelimiter" select="'.'" />
    <xsl:choose>
      <xsl:when test="$oldDelimiter and contains($string, $oldDelimiter)">
        <xsl:value-of select="concat(substring-before($string, $oldDelimiter), $newDelimiter)" />
        <xsl:call-template name="changeTimeDelimiter">
          <xsl:with-param name="string" select="substring-after($string, $oldDelimiter)" />
          <xsl:with-param name="oldDelimiter" select="$oldDelimiter" />
          <xsl:with-param name="newDelimiter" select="$newDelimiter" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>