<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output
    method="xml"
    indent="no"
    encoding="utf-8"
    omit-xml-declaration="yes"/>

  <xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="whitespace"/>

  <xsl:variable name="upper" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <xsl:variable name="lower" select="'abcdefghijklmnopqrstuvwxyz'"/>

  <xsl:template name="string-ascii-tolower">
    <xsl:param name="string" select="."/>
    <xsl:value-of select="translate($string, $upper, $lower)"/>
  </xsl:template>

  <xsl:template match="information"/>

  <xsl:template match="content">
    <code language="{/file/information/type}">
      <xsl:apply-templates/>
    </code>
  </xsl:template>

  <xsl:template match="line">
    <xsl:apply-templates/>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="line[position()=last()]">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="segment">
    <span>
      <xsl:attribute name="class">
        <xsl:text>code-</xsl:text>
        <xsl:call-template name="string-ascii-tolower">
          <xsl:with-param name="string" select="@type"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="whitespace">
    <xsl:apply-templates/>
  </xsl:template>
</xsl:stylesheet>
