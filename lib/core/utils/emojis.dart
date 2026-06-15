enum Emoji {
  smile,
  heart,
  thumbsUp,
  party,
  clap,
  wink, 
  sunrise, 
  sun, 
  moon,
}

extension EmojiExtension on Emoji {
  String get emoji {
    switch (this) {
      case Emoji.smile:
        return '😊';
      case Emoji.heart:
        return '❤️';
      case Emoji.thumbsUp:
        return '👍';
      case Emoji.party:
        return '🎉';
      case Emoji.clap:
        return '👏';
      case Emoji.wink:
        return '😉';
      case Emoji.sunrise:
        return '🌇';
      case Emoji.sun:
        return '☀️';
      case Emoji.moon:
        return '🌛';
      }
  }

  String get description {
    switch (this) {
      case Emoji.smile:
        return 'Smile';
      case Emoji.heart:
        return 'Heart';
      case Emoji.thumbsUp:
        return 'Thumbs Up';
      case Emoji.party:
        return 'Party';
      case Emoji.clap:
        return 'Clap';
      case Emoji.wink:
        return 'Wink';
      case Emoji.sun:
        return 'Afternoon';
      case Emoji.sunrise:
        return 'Morning';
      case Emoji.moon:
        return 'Night';
      }
  }
}
