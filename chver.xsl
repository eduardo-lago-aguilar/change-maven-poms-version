<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pom="http://maven.apache.org/POM/4.0.0">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" omit-xml-declaration="no" />

  <xsl:param name="version" />

  <!-- match namespace-unaware -->
	<xsl:template match="/*[local-name(.)='project']/*[local-name(.)='version']">
    <xsl:element name="version" namespace="http://maven.apache.org/POM/4.0.0"><xsl:value-of select='$version' /></xsl:element>
    <xsl:apply-templates select="*" />
	</xsl:template>

  <!-- standard copy template -->
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*" />
			<xsl:apply-templates />
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>
