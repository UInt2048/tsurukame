// Copyright 2018 David Sansome
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package api

type pageSpec struct {
	PerPage int    `json:"per_page"`
	NextURL string `json:"next_url"`
}

type subjectCollection struct {
	Pages pageSpec         `json:"pages"`
	Data  []*SubjectObject `json:"data"`
}

type SubjectObject struct {
	ID     int    `'json:"id"`
	Object string `json:"object"`
	Data   struct {
    SRSSystemID            int                      `json:"spaced_repetition_system_id"`
		Level                  int                      `json:"level"`
		Slug                   string                   `json:"slug"`
		HiddenAt               string                   `json:"hidden_at"`
		DocumentURL            string                   `json:"document_url"`
		Character              string                   `json:"character"`
		Characters             string                   `json:"characters"`
		CharacterImages        []CharacterImage         `json:"character_images"`
		Meanings               []MeaningObject          `json:"meanings"`
		AuxiliaryMeanings      []AuxiliaryMeaningObject `json:"auxiliary_meanings"`
		Readings               []ReadingObject          `json:"readings"`
		ComponentSubjectIDs    []int                    `json:"component_subject_ids"`
		AmalgamationSubjectIDs []int                    `json:"amalgamation_subject_ids"`
		PartsOfSpeech          []string                 `json:"parts_of_speech"`
		MeaningMnemonic        string                   `json:"meaning_mnemonic"`
		MeaningHint            string                   `json:"meaning_hint"`
		ReadingMnemonic        string                   `json:"reading_mnemonic"`
		ReadingHint            string                   `json:"reading_hint"`
		ContextSentences       []ContextSentence        `json:"context_sentences"`
		PronunciationAudios    []Audio                  `json:"pronunciation_audios"`
	} `json:"data"`
}

type CharacterImage struct {
	ContentType string `json:"content_type"`
	URL         string `json:"url"`
	Metadata    struct {
		Color        string `json:"color"`
		Dimensions   string `json:"dimensions"`
		StyleName    string `json:"style_name"`
		InlineStyles bool   `json:"inline_styles"`
	}
}

type MeaningObject struct {
	Meaning        string `json:"meaning"`
	Primary        bool   `json:"primary"`
	AcceptedAnswer bool   `json:"accepted_answer"`
}

type AuxiliaryMeaningObject struct {
	Meaning string `json:"meaning"`
	Type    string `json:"type"`
}

type ReadingObject struct {
	Type           string `json:"type"`
	Primary        bool   `json:"primary"`
	Reading        string `json:"reading"`
	AcceptedAnswer bool   `json:"accepted_answer"`
}

type ContextSentence struct {
	En string `json:"en"`
	Ja string `json:"ja"`
}

type Audio struct {
	Url      string `json:"url"`
	Metadata struct {
		Gender           string `json:"gender"`
		SourceId         int    `json:"source_id"`
		Pronunciation    string `json:"pronunciation"`
		VoiceActorId     int    `json:"voice_actor_id"`
		VoiceActorName   string `json:"voice_actor_name"`
		VoiceDescription string `json:"voice_description"`
	} `json:"metadata"`
	ContentType string `json:"content_type"`
}
