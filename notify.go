package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/bwmarrin/discordgo"
	"github.com/jzelinskie/geddit"
)

var (
	config         Config                                     // Config options.
	discord        *discordgo.Session                         // Discord session.
	noTag          = containsIgnoreCase(os.Args, "--no-tag")  // Don't tag anyone in messages.
	listingOptions = geddit.ListingOptions{}                  // Redit listing options.
	reddit         *geddit.OAuthSession                       // Reddit session.
	testRun        = containsIgnoreCase(os.Args, "--test")    // Don't send any messages.
	titleRE        = regexp.MustCompile(".+\\|.+-.+\\[.+\\]") // Title regex.
	thumbsUp       = "1F44D"                                  // Thumbs up emoji.
	thumbsDown     = "1F44E"                                  // Thumbs down emoji.
)

// Credentials represents the credentials needed to access Reddit and Discord.
type Credentials struct {
	DiscordToken       string `json:"discord_token"`        // Bot token for Discord.
	RedditClientID     string `json:"reddit_client_id"`     // Client ID for Reddit.
	RedditClientSecret string `json:"reddit_client_secret"` // Client secret for Reddit.
	RedditPassord      string `json:"reddit_password"`      // Password for Reddit.
	RedditUsername     string `json:"reddit_username"`      // Username for Reddit.
}

// Channel represents a single channel's configuration options.
type Channel struct {
	ID        string   `json:"id"`         // Channel ID.
	Tag       string   `json:"tag"`        // Tag to mention.
	BLAuthors []string `json:"bl_authors"` // Post authors to ignore.
	BLPlayers []string `json:"bl_players"` // Players to ignore.
}

// Config represents all required credentials and configuration.
type Config struct {
	Channels    []Channel   `json:"channels"`    // Channel configurations.
	Credentials Credentials `json:"credentials"` // Reddit/Discord credentials.
	Redirect    string      `json:"redirect"`    // Redirect URL for Reddit.
	Subreddit   string      `json:"subreddit"`   // Subreddit for Reddit.
	UserAgent   string      `json:"user_agent"`  // User agent for Reddit.
}

// loadConfig loads the configuration file.
func loadConfig() error {
	configPath := os.Getenv("SPN_CONFIG")
	if configPath == "" {
		configPath = "config.json"
	}
	s, err := ioutil.ReadFile(configPath)
	if err != nil {
		return err
	}
	return json.Unmarshal(s, &config)
}

// loginReddit logs into Reddit.
func loginReddit() (err error) {
	if reddit, err = geddit.NewOAuthSession(
		config.Credentials.RedditClientID,
		config.Credentials.RedditClientSecret,
		config.UserAgent,
		config.Redirect,
	); err != nil {
		return
	}
	reddit.LoginAuth(
		config.Credentials.RedditUsername,
		config.Credentials.RedditPassord,
	)
	return
}

// loginDiscord logs into Discord.
func loginDiscord() (err error) {
	discord, err = discordgo.New("Bot " + config.Credentials.DiscordToken)
	return
}

// setInitialBefore sets listingOptions.Before to not process too many existing posts.
func setInitialBefore() error {
	posts, err := reddit.SubredditSubmissions(
		config.Subreddit,
		geddit.NewSubmissions,
		geddit.ListingOptions{},
	)
	if err != nil {
		return err
	}
	// Leave a few posts of overlap just in case we missed anything while not running.
	listingOptions.Before = posts[4].FullID
	return nil
}

// containsIgnoreCase checks if a slice of strings contains some string,
// ignoring case for comparisons.
func containsIgnoreCase(a []string, k string) bool {
	k = strings.ToUpper(k)
	for _, s := range a {
		if strings.ToUpper(s) == k {
			return true
		}
	}
	return false
}

// shouldNotify determines whether a post should be announced.
func shouldNotify(post *geddit.Submission) (bool, string) {
	if post.IsSelf {
		return false, "is a self post"
	} else if post.IsSaved {
		return false, "is already saved"
	} else if !titleRE.Match([]byte(post.Title)) {
		return false, "is not a score post"
	}
	return true, ""
}

// getPlayerName extracts the player name from a post title.
func getPlayerName(title string) string {
	return strings.TrimSpace(strings.Split(title, "|")[0])
}

// addReactions adds thumbs up/down reactions to a message.
func addReactions(msg *discordgo.Message) error {
	// if err := discord.MessageReactionAdd(msg.ChannelID, msg.ID, thumbsUp); err != nil {
	// 	return err
	// }
	// return discord.MessageReactionAdd(msg.ChannelID, msg.ID, thumbsDown)
	return nil // I don't know what the emoji IDs are supposed to be.
}

// processPosts goes through new posts and announces them if necessary.
func processPosts(posts []*geddit.Submission) {
	for _, post := range posts {
		listingOptions.Before = post.FullID

		should, reason := shouldNotify(post)
		if !should {
			log.Printf("skipping %s: %s", post.Title, reason)
			continue
		}

		log.Printf("notifying for post: %s", post.Title)
		for _, channel := range config.Channels {
			player := getPlayerName(post.Title)
			if containsIgnoreCase(channel.BLPlayers, player) {
				log.Printf("player %s is blacklisted", player)
				continue
			} else if containsIgnoreCase(channel.BLAuthors, post.Author) {
				log.Printf("author %s is blacklisted", post.Author)
				continue
			}

			url := fmt.Sprintf("https://redd.it/%s", post.ID)
			var text string
			if noTag {
				text = fmt.Sprintf("%s\n%s", post.Title, url)
			} else {
				text = fmt.Sprintf("%s: %s\n%s", channel.Tag, post.Title, url)
			}

			log.Printf("sending: %s", strings.Replace(text, "\n", " \\n ", -1))
			if !testRun {
				msg, err := discord.ChannelMessageSend(channel.ID, text)
				if err != nil {
					log.Printf("sending message failed: %s", err)
					continue
				}

				if err = addReactions(msg); err != nil {
					log.Printf("adding reactions failed: %s", err)
				}

				if err = reddit.Save(post, ""); err != nil {
					log.Printf("couldn't save post: %s", err)
				}
			}
		}
	}

}

func main() {
	log.Printf("Running with --test=%t, --no-tag=%t", testRun, noTag)

	if err := loadConfig(); err != nil {
		log.Fatalf("could load config: %s", err)
	}
	if err := loginReddit(); err != nil {
		log.Fatalf("couldn't log into Reddit: %s", err)
	}
	if err := loginDiscord(); err != nil {
		log.Fatalf("couldn't log into Discord: %s", err)
	}

	if err := setInitialBefore(); err != nil {
		log.Printf("couldn't set initial before value: %s", err)
	}

	// Both Reddit and Discord's auth tokens will expire eventually,
	// so we'll just quit and reboot every now and then.
	go func() {
		time.Sleep(59 * time.Minute)
		log.Println("exiting on time")
		os.Exit(0)
	}()

	for {
		posts, err := reddit.SubredditSubmissions(
			config.Subreddit,
			geddit.NewSubmissions,
			listingOptions,
		)
		if err != nil {
			log.Printf("couldn't get new posts: %s", err)
			time.Sleep(5 * time.Minute)
		} else {
			processPosts(posts)
			time.Sleep(time.Minute)
		}
	}
}
