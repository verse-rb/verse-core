# frozen_string_literal: true

module Verse
  module Util
    # Inflector used to conjugate english verbs to and from the past tense
    # this is used to generate events related to commands
    class Inflector
      # https://www.grammar.cl/Past/Irregular_Verbs_List.htm
      PAST_TENSE_EXCEPTIONS = {
        "arise" => "arisen",
        "babysit" => "babysat",
        "be"	=> "were",
        "beat" => "beaten",
        "become" => "become",
        "bend" => "bent",
        "begin" => "begun",
        "bet" => "bet",
        "bind" => "bound",
        "bite" => "bitten",
        "bleed" => "bled",
        "blow" => "blown",
        "break" => "broken",
        "breed" => "bred",
        "bring" => "brought",
        "broadcast" => "broadcast",
        "build" => "built",
        "buy" => "bought",
        "catch" => "caught",
        "choose" => "chosen",
        "come" => "come",
        "cost" => "cost",
        "cut" => "cut",
        "deal" => "dealt",
        "dig" => "dug",
        "do" => "done",
        "draw" => "drawn",
        "drink" => "drunk",
        "drive" => "driven",
        "eat" => "eaten",
        "fall" => "fallen",
        "feed" => "fed",
        "feel" => "felt",
        "fight" => "fought",
        "find" => "found",
        "fly" => "flown",
        "forbid" => "forbidden",
        "forget" => "forgotten",
        "forgive" => "forgiven",
        "freeze" => "frozen",
        "get" => "got",
        "give" => "given",
        "go" => "gone",
        "grow" => "grown",
        "hang" =>	"hung",
        "have" => "had",
        "hear" => "heard",
        "hide" => "hidden",
        "hit" => "hit",
        "hold" => "held",
        "hurt" => "hurt",
        "keep" => "kept",
        "know" => "known",
        "lay" => "laid",
        "lead" => "led",
        "leave" => "left",
        "lend" => "lent",
        "let" => "let",
        "lie" =>	"lain",
        "light" => "lit",
        "lose" => "lost",
        "make" => "made",
        "mean" => "meant",
        "meet" => "met",
        "pay" => "paid",
        "put" => "put",
        "quit" => "quit",
        "read" =>	"read",
        "ride" => "ridden",
        "ring" => "rung",
        "rise" => "risen",
        "run" => "run",
        "say" => "said",
        "see" => "seen",
        "sell" => "sold",
        "send" => "sent",
        "set" => "set",
        "shake" => "shaken",
        "shine" => "shone",
        "shoot" => "shot",
        "show" => "shown",
        "shut" => "shut",
        "sing" => "sung",
        "sink" => "sunk",
        "sit" => "sat",
        "sleep" => "slept",
        "slide" => "slid",
        "speak" => "spoken",
        "speed" => "sped",
        "spend" => "spent",
        "spin" => "spun",
        "spread" => "spread",
        "stand" => "stood",
        "steal" => "stolen",
        "stick" => "stuck",
        "sting" => "stung",
        "strike" => "struck",
        "swear" => "sworn",
        "sweep" => "swept",
        "swim" => "swum",
        "swing" => "swung",
        "take" => "taken",
        "teach" => "taught",
        "tear" => "torn",
        "tell" => "told",
        "think" => "thought",
        "throw" => "thrown",
        "understand" => "understood",
        "wake" => "woken",
        "wear" => "worn",
        "win" => "won",
        "withdraw" => "withdrawn",
        "write" => "written",
      }.freeze

      PLURAL_EXCEPTIONS = {
        "child" => "children",
        "person" => "people",
        "man" => "men",
        "woman" => "women"
      }.freeze

      def initialize(verb_exceptions = PAST_TENSE_EXCEPTIONS, plural_exceptions = PLURAL_EXCEPTIONS)
        @verb_exceptions = verb_exceptions

        @plural_exceptions = plural_exceptions
        @singular_exceptions = plural_exceptions.lazy.map(&:reverse).to_h.freeze
      end

      def pluralize(word, count = 2)
        return word if count <= 1

        @plural_exceptions.fetch(word) {
          "#{word}s"
        }
      end

      def singularize(word)
        @singular_exceptions.fetch(word) {
          word.gsub(/s$/, "")
        }
      end

      # Inflect verbs to past tense.
      # work => worked
      # bite => bitten because in exception list
      # create_object => object_created
      def inflect_past(verb)
        words = verb.to_s.gsub(/[^a-zA-Z\ ]/, "_").split("_")

        verb = words[0]

        paste_tense_verb = @verb_exceptions.fetch(verb) do
          case verb
          when /e$/
            "#{verb}d"
          when /[^oa]y$/
            "#{verb[0..-2]}ied"
          when /[^aeiou][aeiou][glmpt]$/
            "#{verb}#{verb[-1]}ed"
          when /c$/
            "#{verb}ked" # picnic / picnicked
          else
            "#{verb}ed"
          end
        end

        [*words[1..], paste_tense_verb].join("_")
      end
    end
  end
end
