#!usr/bin/env python

import discord
import json
import logging
import os
import praw
import re
import sys

score_post_re = re.compile(".+\|.+-.+\[.+\]")
parens_re = re.compile("\((.*?)\)")

reddit = praw.Reddit(
    client_id=os.environ["REDDIT_CLIENT_ID"],
    client_secret=os.environ["REDDIT_CLIENT_SECRET"],
    username=os.environ["REDDIT_USERNAME"],
    user_agent=os.environ["REDDIT_USERNAME"],
    password=os.environ["REDDIT_PASSWORD"],
)
subreddit = reddit.subreddit(os.environ.get("SPN_SUBREDDIT", "osugame"))

discord_client = discord.Client()
discord_reactions = ["\U0001F44D", "\U0001F44E"]


class DiscordChannel(object):
    """Container for channel config and a discord.Channel object."""
    def __init__(self, *, channel, tag, player_blacklist, submitter_blacklist):
        self.id = channel.id
        self.channel = channel
        self.tag = tag
        self.player_blacklist = [x.lower() for x in player_blacklist]
        self.submitter_blacklist = [x.lower() for x in submitter_blacklist]

    def __repr__(self):
        return "<channel %s>" % self.id


def player_name(s):
    """Parse a player name from a title."""
    s = s[:s.index("|")]
    for cap in parens_re.findall(s):
        s = s.replace("(%s)" % cap, "")
    return s.strip().lower()


def run(x):
    """Pretend async doesn't exist."""
    return discord_client.loop.run_until_complete(x)


def process_post(post):
    if not score_post_re.match(post.title):
        logger.info("No match: %s" % post.title)
        return
    if post.saved:
        logger.info("Already saved: %s" % post.title)
        return

    player = player_name(post.title)
    for channel in channels:
        if player_name in channel.player_blacklist:
            logger.info("%s is in %s's blacklist" % (player, channel))
            continue
        if post.author.name.lower() in channel.submitter_blacklist:
            logger.info("/u/%s is in %s's blacklist" % (post.author, channel))
            continue

        msg = "{0.title}\n{0.shortlink} (post by `/u/{0.author}`)".format(post)
        if not no_tag:
            msg = "%s: %s" % (channel.tag, msg)

        logger.info("Sending to %s: %s" % (channel.id, msg))
        if not test:
            msg = run(discord_client.send_message(channel.channel, msg))
            for reaction in discord_reactions:
                run(discord_client.add_reaction(msg, reaction))

    if not test:
        post.save()


with open(os.environ.get("DISCORD_CHANNEL_CONF", "channels.json")) as f:
    channels = [
        DiscordChannel(
            channel=discord.Object(id=channel["id"]),
            tag=channel["tag"],
            player_blacklist=channel["player_blacklist"],
            submitter_blacklist=channel["submitter_blacklist"],
        )
        for channel in json.load(f)
    ]
run(discord_client.login(os.environ["DISCORD_TOKEN"]))
test = "--test" in sys.argv
no_tag = "--no-tag" in sys.argv
logger = logging.getLogger()
logging.basicConfig(format="%(asctime)s: %(message)s", level=logging.INFO)

if __name__ == "__main__":
    logging.info("test=%s, no_tag=%s" % (test, no_tag))
    channels_str = "\n".join(str(c.__dict__) for c in channels)
    logging.info("Channels:\n%s" % channels_str)

    while True:
        try:
            for post in subreddit.stream.submissions():
                process_post(post)
        except KeyboardInterrupt:
            print("\nExiting")
            break
        except Exception as e:
            print("Exception: %s" % e)

    run(discord_client.close())
