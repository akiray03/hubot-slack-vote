# Description:
#   hubot slack vote
#
# Configuration:
#   HUBOT_SLACK_TOKEN # hubot integration token
#
# Commands:
#   hubot vote :emoji: :emoji2:
#
# Author:
#   akiray03

Promise = require 'promise'
_ = require 'underscore'

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
    votes = _.uniq(votes)

    msg_id = msg.message.id
    channel = msg.message.rawMessage.channel
    token = process.env.HUBOT_SLACK_TOKEN
    unless token
      robot.logger.error "HUBOT_SLACK_TOKEN does not defined."
      return

    robot.logger.info votes

    handle_reactions(msg, token, votes, channel, msg_id)

  handle_reactions = (msg, token, votes, channel, msg_id) ->
      if votes.length > 0
        vote = votes.shift()
        reactions(msg, token, vote, channel, msg_id)
          .then (json) ->
            handle_reactions(msg, token, votes, channel, msg_id)

  reactions = (msg, token, vote, channel, msg_id) ->
    params = "token=#{ token }&name=#{ vote }&channel=#{ channel }&timestamp=#{ msg_id }"
    url = "https://slack.com/api/reactions.add?#{ params }"

    new Promise (resolve, reject) ->
      robot.http(url).get() (err, res, body) ->
        robot.logger.info "#{ msg.envelope.room }:#{ msg_id } reactions #{ vote } --> #{ body }"
        if err
          msg.send "auto reactions failed (#{ vote })"
          reject()
        if body
          j = JSON.parse(body)
          if (not j.ok) and (j.error)
            msg.send "auto reactions failed (`:#{ vote }:` -- reason: #{ j.error })"
        resolve(j)
