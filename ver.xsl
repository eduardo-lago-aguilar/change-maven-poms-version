<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="text" encoding="UTF-8"/>
	<xsl:strip-space elements="*" />

  <!-- match namespace-unaware -->
	<xsl:template match="/*[local-name(.)='project']/*[local-name(.)='version']">
    <xsl:value-of select="text()" />
	</xsl:template>

  <!-- overwrite default text copy template -->
  <xsl:template match="text()|@*" />

</xsl:stylesheet>
