// MARK: - Inbound

import Foundation
import PipecatClientIOS

// enums just for namespacing
enum WebSocketMessages {
    
    // MARK: - Inbound
    
    enum Inbound {
        struct SetupComplete: Decodable {
            var setupComplete: EmptyObject
            
            struct EmptyObject: Decodable {}
        }
        
        struct AudioOutput: Decodable {
            var serverContent: ServerContent
            
            func audioBytes() -> Data? {
                guard let part = serverContent.modelTurn?.parts.first else {
                    return nil
                }
                return Data(base64Encoded: part.inlineData.data)
            }
            
            struct ServerContent: Decodable {
                var modelTurn: ModelTurn?
                var outputTranscription: OutputTranscription?
                
                struct ModelTurn: Decodable {
                    var parts: [Part]
                    
                    struct Part: Decodable {
                        var inlineData: InlineData
                        
                        struct InlineData: Decodable {
                            var data: String
                        }
                    }
                }
                
                struct OutputTranscription: Decodable {
                    var text: String
                }
            }
        }
        
        struct Interrupted: Decodable {
            var serverContent: ServerContent
            
            struct ServerContent: Decodable {
                var interrupted = true
            }
        }
    }
    
    // MARK: - Outbound
    
    enum Outbound {
        struct Setup: Encodable {
            var setup: Setup
            
            struct Setup: Encodable {
                var model: String
                var generationConfig: GenerationConfig
                var systemInstruction: Content
            }
            
            init(model: String, generationConfig: GenerationConfig, systemInstruction: Content) {
                self.setup = .init(model: model, generationConfig: generationConfig, systemInstruction: systemInstruction)
            }
        }
        
        struct GenerationConfig: Encodable {
            
            /*
             {
             "stopSequences": [
             string
             ],
             "responseMimeType": string,
             "responseSchema": {
             object (Schema)
             },
             "responseModalities": [
             enum (Modality)
             ],
             "candidateCount": integer,
             "maxOutputTokens": integer,
             "temperature": number,
             "topP": number,
             "topK": integer,
             "seed": integer,
             "presencePenalty": number,
             "frequencyPenalty": number,
             "responseLogprobs": boolean,
             "logprobs": integer,
             "enableEnhancedCivicAnswers": boolean,
             "speechConfig": {
             object (SpeechConfig)
             },
             "thinkingConfig": {
             object (ThinkingConfig)
             },
             "mediaResolution": enum (MediaResolution)
             }
             */
            
            let responseModalities: [Modality]
            let speechConfig: SpeechConfig
            let temperature: Double
            
            enum Modality: String, RawRepresentable, Codable {
                case audio = "AUDIO"
            }
            
            struct SpeechConfig: Encodable {
                /*
                 {
                 "voiceConfig": {
                 object (VoiceConfig)
                 },
                 "languageCode": string
                 }
                 */
                
                let voiceConfig: VoiceConfig
                let languageCode: String
                
                struct VoiceConfig: Encodable {
                    
                    /*
                     {
                     
                     // voice_config
                     "prebuiltVoiceConfig": {
                     object (PrebuiltVoiceConfig)
                     }
                     // Union type
                     }
                     */
                    let prebuiltVoiceConfig: PrebuiltVoiceConfig
                    
                    struct PrebuiltVoiceConfig: Encodable {
                        /*
                         {
                           "voiceName": string
                         }
                         */
                        let voiceName: String
                    }
                }
            }
        }
        
        struct Content: Encodable {
            let parts: [Part]
            let role: String
            
            struct Part: Encodable {
                let thought: Bool
                let text: String
            }
        }
        
        
        struct TextInput: Encodable {
            var clientContent: ClientContent
            
            struct ClientContent: Encodable {
                var turns: [Turn]
                var turnComplete = true
                
                struct Turn: Encodable {
                    var role: String
                    var parts: [Text]
                    
                    struct Text: Encodable {
                        var text: String
                    }
                }
            }
            
            init(text: String, role: String) {
                self.clientContent = .init(
                    turns: [
                        .init(role: role == "user" ? "user" : "model", parts: [.init(text: text)])
                    ]
                )
            }
        }
        
        struct AudioInput: Encodable {
            var realtimeInput: RealtimeInput
            
            struct RealtimeInput: Encodable {
                var audio: Blob
                
                struct Blob: Encodable {
                    var mimeType: String
                    var data: String
                }
            }
            
            init(audio: Data) {
                realtimeInput = .init(audio: .init(
                    mimeType: "audio/pcm;rate=\(Int(AudioCommon.serverAudioFormat.sampleRate))",
                    data: audio.base64EncodedString()
                ))
            }
        }
        
        
        struct VideoInput: Encodable {
            var realtimeInput: RealtimeInput
            
            struct RealtimeInput: Encodable {
                var video: Blob
                
                struct Blob: Encodable {
                    var mimeType: String
                    var data: String
                }
            }
            
            init(video: Data) {
                realtimeInput = .init(video: .init(
                    mimeType: "image/jpeg",
                    data: video.base64EncodedString()
                ))
            }
        }
    }
}
