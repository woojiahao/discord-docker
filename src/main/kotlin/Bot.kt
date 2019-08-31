import me.aberrantfox.kjdautils.api.startBot

fun main() {
  val botToken = System.getenv("BOT_TOKEN")
  startBot(botToken) { configure { prefix = "!" } }
}