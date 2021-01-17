 shellPrompt := { state =>
  def textColor(color: Int)      = { s"\033[38;5;${color}m" }
  def backgroundColor(color:Int) = { s"\033[48;5;${color}m" }
  def reset                      = { s"\033[0m" }

	// Format prompt with string, fg and bg
  def formatTextBG(str: String)(txtColor: Int, backColor: Int) = {
    s"${textColor(txtColor)}${backgroundColor(backColor)}${str}${reset}"
  }
	// Format prompt with string and colour
  def formatText(str: String)(txtColor: Int) = {
    s"${textColor(txtColor)}${str}${reset}"
  }
  val red    = 1
  val green  = 2
  val yellow = 11
  val white  = 15
  val black  = 16
  val orange = 166

  formatText(s"\n[${name.value}]")(white) +
   "\n " +
   formatText("\u276f")(green) +
   formatText("\u276f")(yellow) +
   formatText("\u276f ")(red)
}
