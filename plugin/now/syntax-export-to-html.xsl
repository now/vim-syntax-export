<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/TR/xhtml1/strict">
  <xsl:output method="xml" indent="no" encoding="utf-8"/>

  <xsl:strip-space elements="content"/>

  <xsl:param name="want-line-numbers" select="0"/>

  <xsl:template match="file">
    <html>
      <head>
        <title>
          Syntax Export of <xsl:value-of select="information/path"/>
        </title>
        <style type="text/css">
          .Comment { color: #257325; }
          .Constant { color: #951616; }
          .Special { color: #f02626; }
          .Identifier { color: #2f5a9b; }
          .Statement { color: #766020; }
          .PreProc { color: #93376e; }
          .Type { color: #602f80; }
          .Underlined { text-decoration: underline; }
          .Number { color: #181818; }
          .Error { color: #f0a500; }
          .Todo { background-color: #f0a500; }
          .Normal { color: #181818; }
          .line-number { background: orange; }
        </style>
      </head>
      <body>
        <xsl:apply-templates select="content"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="content">
    <pre class="language-{/file/information/type}">
      <xsl:apply-templates/>
    </pre>
  </xsl:template>

  <xsl:template match="line">
    <xsl:if test="$want-line-numbers">
      <span class="line-number">
        <xsl:value-of select="format-number(position(), '00000')"/>
        <xsl:text>: </xsl:text>
      </span>
    </xsl:if>

    <xsl:apply-templates/>

    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="segment">
    <span class="{@type}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="whitespace">
    <xsl:apply-templates/>
  </xsl:template>
</xsl:stylesheet>
