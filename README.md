_This project is in ALPHA phase.  Not much works, but I envision in time it will._

# robbi-bot
Slack-to-coffee shop integration for ZappiStore!

## Configuration

1. Install app to your slack. (If you aren't sure how to do this, submit an issue and I'll write something up)
2. Export API keys on wherever you choose to host the app (e.g. I'm using Heroku). `SLACK_REDIRECT_URI` should be the finish auth URI you provide in the slack app interface, e.g. `https://my-foo-app.com/finish_auth`
3. Navigate to `https://my-foo-app/begin_auth`
4. Your app should authenticate with your slack workspace, now you can start using it.

## Usage

This app fundamentally assumes some sort of client-server model.  In my case, there is a server being hosted on a Raspberry Pi at the coffee shop I go to.  That code will live in [this repo](https://github.com/StuartHadfield/robbi-bot-server).

1. Ordering through messages
  - You can order by PMing the bot.
  - Test responsiveness by saying `Hi Robbi`
  - Ask for help with `Help`
  - See the menu with `Menu`
  - Order with any code off the menu
2. Ordering through slash commands
  - You should be able to perform `/slash_commands` to interact with Robbi.
  - Ask for help with `/robbi_help`
  - See the menu with `/robbi_menu`
  - Order with any code off the menu, e.g. `/robbi_large_flat_white`
3. Responsiveness
  - RobbiBot should tell you two things
    - That your order has been sent to the coffee shop
    - That the coffee shop has seen your order - you should probably head down and collect it now.

## Contribution
1. Please do :)
  - Just submit a PR.
