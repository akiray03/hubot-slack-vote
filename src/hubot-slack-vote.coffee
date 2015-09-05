# Description:
#   hubot slack vote
#
# Configuration:
#   SLACK_ACCESS_TOKEN  # Slack API Token (does not Integration token)
#
# Commands:
#   hubot vote :emoji: :emoji2:
#
# Author:
#   akiray03

module.exports = (robot) ->

  robot.respond /vote(\s|\r\n|\n:?)(.*)/, (msg) ->
    robot.logger.info msg.message.text
    votes = []
    pattern = /:[a-z0-9+_-]+:/
    text = msg.message.text.replace(/(\r|\n)/g, ' ')
    while (pos = text.search(pattern)) >= 0
      vote = text.match(pattern)[0]
      text = text.substring(pos + vote.length)
      vote = vote.replace(/^\s+/, '').replace(/\s+$/, '').replace(/\:/g, '')
      vote = 'thumbsup' if vote == '+1'
      votes.push vote

    msg_id = msg.message.id
    channel = msg.message.rawMessage.channel
    token = process.env.SLACK_ACCESS_TOKEN
    unless token
      robot.logger.error "SLACK_ACCESS_TOKEN does not defined."
      return

    robot.logger.info votes
    i = 0
    for vote in votes
      reactions(msg, token, vote, channel, msg_id, 500 * i)
      i += 1

  reactions = (msg, token, vote, channel, msg_id, delay) ->
    delay = delay || 0
    params = "token=#{ token }&name=#{ vote }&channel=#{ channel }&timestamp=#{ msg_id }"
    url = "https://slack.com/api/reactions.add?#{ params }"
    setTimeout ->
      robot.http(url).get() (err, res, body) ->
        robot.logger.info "#{ msg.envelope.room }:#{ msg_id } reactions #{ vote } --> #{ body }"
        if err
          msg.send "auto reactions failed (#{ vote })"
          return
        if body
          j = JSON.parse(body)
          if (not j.ok) and (j.error)
            msg.send "auto reactions failed (#{ vote } -- reason: #{ body.error })"
            return
      , delay

