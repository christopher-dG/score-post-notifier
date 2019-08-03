#!usr/bin/env python

import json
import os
import re
import sys

import discord
import praw

score_post_re = re.compile(".+\|.+-.+\[.+\]")
parens_re = re.compile("\((.*?)\)")

reddit = praw.Reddit(
    client_id=os.environ["REDDIT_CLIENT_ID"],
    client_secret=os.environ["REDDIT_CLIENT_SECRET"],
    username=os.environ["REDDIT_USERNAME"],
    user_agent=os.environ["REDDIT_USERNAME"],
    password=os.environ["REDDIT_PASSWORD"],
)
subreddit = reddit.subreddit("osugame")
discord_client = None
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


def escape(s):
    """Escape Discord formatting."""
    return s\
        .replace("_", "\_")\
        .replace("~", "\~")\
        .replace("*", "\*")\
        .replace("`", "\`")


def parse_player(s):
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
        print("No match: %s" % post.title)
        return
    if not test and post.saved:
        print("Already saved: %s" % post.title)
        return

    player = parse_player(post.title)
    for channel in channels:
        if player in channel.player_blacklist:
            print("%s is in %s's blacklist" % (player, channel))
            continue
        if post.author.name.lower() in channel.submitter_blacklist:
            print("/u/%s is in %s's blacklist" % (post.author, channel))
            continue

        title = escape(post.title)
        msg = "%s\n%s (post by `/u/%s`)" % (title, post.shortlink, post.author)
        if not no_tag:
            msg = "%s: %s" % (channel.tag, msg)

        print("Sending to %s: %s" % (channel.id, msg))
        if not test:
            msg = run(discord_client.send_message(channel.channel, msg))
            for reaction in discord_reactions:
                run(discord_client.add_reaction(msg, reaction))

    if not test:
        post.save()


with open("channels.json") as f:
    channels = [
        DiscordChannel(
            channel=discord.Object(id=channel["id"]),
            tag=channel["tag"],
            player_blacklist=channel["player_blacklist"],
            submitter_blacklist=channel["submitter_blacklist"],
        )
        for channel in json.load(f)
    ]
test = os.getenv("TEST", "").lower() == "true"
no_tag = os.getenv("NO_TAG", "").lower() == "true"

def handler(_event, _context):
    global discord_client
    discord_client = discord.Client()
    run(discord_client.login(os.environ["DISCORD_TOKEN"]))
    print("test=%s, no_tag=%s" % (test, no_tag))
    channels_str = "\n".join(str(c.__dict__) for c in channels)
    print("Channels:\n%s" % channels_str)

    try:
        for post in subreddit.new():
            print("Processing post %s" % post.id)
            process_post(post)
    except Exception as e:
        print("Exception: %s" % e)

    run(discord_client.close())
