<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <!-- Output Type Declaration-->
  <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>

  <!-- Entry Point -->
  <xsl:template match="/">
    <ns:reevaluateRatesRequest xmlns:ns="http://schemas.benefitfocus.com/enrollment/general/2010/1/3/" xmlns:ten="http://schemas.benefitfocus.com/common/general/2010/1/1/tenant" xmlns:mem="http://schemas.benefitfocus.com/member/general/2010/2/1/memberIdentification" xmlns:car="http://schemas.benefitfocus.com/common/general/2010/1/1/carrierIdentification">
      <ten:tenant>
        <type>CarrierIndividualMarket</type>
        <car:carrierIdentification>
          <BenefitfocusCarrierId>5DE53F0C768A393DE040640A6E11267C</BenefitfocusCarrierId>
          <carrierShortName>AETNA</carrierShortName>
        </car:carrierIdentification>
      </ten:tenant>
      <mem:memberIdentification>
        <xsl:attribute name="referenceId">
          <xsl:value-of select="invalidFutureRatesEvent/memberIdentification/@referenceId"/>
        </xsl:attribute>
        <!--Optional:-->
        <BenefitfocusPersonId>
          <xsl:value-of select="invalidFutureRatesEvent/memberIdentification/BenefitfocusPersonId"/>
        </BenefitfocusPersonId>
        <!--Optional:-->
        <sponsorId>
          <BenefitfocusSponsorId>
            <xsl:value-of select="invalidFutureRatesEvent/memberIdentification/sponsorId/BenefitfocusSponsorId"/>
          </BenefitfocusSponsorId>
          <sponsorName>
            <xsl:value-of select="invalidFutureRatesEvent/memberIdentification/sponsorId/sponsorName"/>
          </sponsorName>
          <!--Optional:
               <sponsorCarrierId>?</sponsorCarrierId>
			   -->
        </sponsorId>
      </mem:memberIdentification>
      <ns:asOfDate>
        <xsl:value-of select="invalidFutureRatesEvent/effectiveDate"/>
      </ns:asOfDate>
    </ns:reevaluateRatesRequest>
  </xsl:template>
</xsl:stylesheet>