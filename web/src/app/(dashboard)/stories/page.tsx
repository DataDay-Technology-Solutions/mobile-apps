'use client'

import { useEffect, useState, useRef } from 'react'
import { useAuth } from '@/contexts/auth-context'
import { useClassroom } from '@/contexts/classroom-context'
import { storyService } from '@/services/story'
import { Header } from '@/components/layout/header'
import { Card, CardContent, Button, Avatar, Input } from '@/components/ui'
import { cn } from '@/lib/utils'
import {
  Plus,
  Heart,
  MessageCircle,
  Image as ImageIcon,
  X,
  Send,
  MoreHorizontal,
  Trash2,
} from 'lucide-react'
import type { Story, StoryComment, MediaType } from '@/types'
import { timeAgo } from '@/types'

export default function StoriesPage() {
  const { user } = useAuth()
  const { selectedClassroom } = useClassroom()
  const [stories, setStories] = useState<Story[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreateStory, setShowCreateStory] = useState(false)

  useEffect(() => {
    if (!selectedClassroom) {
      setLoading(false)
      return
    }

    const fetchStories = async () => {
      setLoading(true)
      try {
        const fetchedStories = await storyService.getStoriesForClass(selectedClassroom.id)
        setStories(fetchedStories)
      } catch (error) {
        console.error('Failed to fetch stories:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchStories()

    // Subscribe to story updates
    const unsubscribe = storyService.subscribeToStories(selectedClassroom.id, (updatedStories) => {
      setStories(updatedStories)
    })

    return () => {
      unsubscribe()
    }
  }, [selectedClassroom])

  const handleLike = async (story: Story) => {
    if (!user) return
    try {
      const updatedStory = await storyService.toggleLike(story.id, user.id)
      setStories(prev => prev.map(s => s.id === updatedStory.id ? updatedStory : s))
    } catch (error) {
      console.error('Failed to toggle like:', error)
    }
  }

  const handleDelete = async (storyId: string) => {
    if (!confirm('Are you sure you want to delete this story?')) return
    try {
      await storyService.deleteStory(storyId)
      setStories(prev => prev.filter(s => s.id !== storyId))
    } catch (error) {
      console.error('Failed to delete story:', error)
    }
  }

  const handleStoryCreated = (newStory: Story) => {
    setStories(prev => [newStory, ...prev])
    setShowCreateStory(false)
  }

  const isTeacher = user?.role === 'teacher'

  return (
    <>
      <Header title="Stories" />
      <main className="flex-1 p-6 overflow-y-auto">
        <div className="max-w-2xl mx-auto">
          {/* Create Story Button */}
          {isTeacher && selectedClassroom && (
            <Button
              onClick={() => setShowCreateStory(true)}
              className="w-full mb-6"
            >
              <Plus className="h-4 w-4 mr-2" />
              Create Story
            </Button>
          )}

          {/* Stories Feed */}
          {!selectedClassroom ? (
            <Card>
              <CardContent className="py-12 text-center">
                <p className="text-gray-500">Select a classroom to view stories</p>
              </CardContent>
            </Card>
          ) : loading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <Card key={i}>
                  <CardContent className="p-4 animate-pulse">
                    <div className="flex items-center gap-3 mb-4">
                      <div className="h-10 w-10 rounded-full bg-gray-200" />
                      <div className="flex-1">
                        <div className="h-4 w-24 bg-gray-200 rounded mb-1" />
                        <div className="h-3 w-16 bg-gray-200 rounded" />
                      </div>
                    </div>
                    <div className="h-20 bg-gray-200 rounded mb-4" />
                    <div className="flex gap-4">
                      <div className="h-4 w-16 bg-gray-200 rounded" />
                      <div className="h-4 w-16 bg-gray-200 rounded" />
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : stories.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <div className="mx-auto h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center mb-4">
                  <ImageIcon className="h-6 w-6 text-gray-400" />
                </div>
                <p className="text-gray-500 mb-4">No stories yet</p>
                {isTeacher && (
                  <Button size="sm" onClick={() => setShowCreateStory(true)}>
                    <Plus className="h-4 w-4 mr-2" />
                    Create First Story
                  </Button>
                )}
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {stories.map((story) => (
                <StoryCard
                  key={story.id}
                  story={story}
                  currentUserId={user?.id}
                  onLike={() => handleLike(story)}
                  onDelete={() => handleDelete(story.id)}
                />
              ))}
            </div>
          )}
        </div>

        {/* Create Story Modal */}
        {showCreateStory && selectedClassroom && user && (
          <CreateStoryModal
            onClose={() => setShowCreateStory(false)}
            onCreated={handleStoryCreated}
            classroomId={selectedClassroom.id}
            userId={user.id}
            userName={user.name}
          />
        )}
      </main>
    </>
  )
}

interface StoryCardProps {
  story: Story
  currentUserId?: string
  onLike: () => void
  onDelete: () => void
}

function StoryCard({ story, currentUserId, onLike, onDelete }: StoryCardProps) {
  const [showComments, setShowComments] = useState(false)
  const [comments, setComments] = useState<StoryComment[]>([])
  const [newComment, setNewComment] = useState('')
  const [loadingComments, setLoadingComments] = useState(false)
  const [showMenu, setShowMenu] = useState(false)

  const isLiked = currentUserId ? story.liked_by_ids.includes(currentUserId) : false
  const isAuthor = currentUserId === story.author_id
  const authorInitials = story.author_name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)

  const loadComments = async () => {
    if (!showComments) {
      setShowComments(true)
      setLoadingComments(true)
      try {
        const fetchedComments = await storyService.getComments(story.id)
        setComments(fetchedComments)
      } catch (error) {
        console.error('Failed to fetch comments:', error)
      } finally {
        setLoadingComments(false)
      }
    } else {
      setShowComments(false)
    }
  }

  const handleAddComment = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newComment.trim() || !currentUserId) return

    try {
      // We need user name here - for now use a placeholder
      const comment = await storyService.addComment(
        story.id,
        currentUserId,
        'You', // This would come from auth context in real app
        newComment.trim()
      )
      setComments(prev => [...prev, comment])
      setNewComment('')
    } catch (error) {
      console.error('Failed to add comment:', error)
    }
  }

  return (
    <Card>
      <CardContent className="p-4">
        {/* Header */}
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-3">
            <Avatar initials={authorInitials} size="md" />
            <div>
              <p className="font-medium text-gray-900">{story.author_name}</p>
              <p className="text-sm text-gray-500">{timeAgo(story.created_at)}</p>
            </div>
          </div>
          {isAuthor && (
            <div className="relative">
              <button
                onClick={() => setShowMenu(!showMenu)}
                className="p-2 rounded-lg hover:bg-gray-100 text-gray-400"
              >
                <MoreHorizontal className="h-5 w-5" />
              </button>
              {showMenu && (
                <div className="absolute right-0 mt-1 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-10">
                  <button
                    onClick={() => {
                      onDelete()
                      setShowMenu(false)
                    }}
                    className="flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 w-full"
                  >
                    <Trash2 className="h-4 w-4" />
                    Delete
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Content */}
        {story.content && (
          <p className="text-gray-900 mb-3 whitespace-pre-wrap">{story.content}</p>
        )}

        {/* Media */}
        {story.media_urls.length > 0 && (
          <div className="mb-3 rounded-lg overflow-hidden">
            {story.media_type === 'image' && (
              <img
                src={story.media_urls[0]}
                alt="Story media"
                className="w-full max-h-96 object-cover"
              />
            )}
            {story.media_type === 'video' && (
              <video
                src={story.media_urls[0]}
                controls
                className="w-full max-h-96"
              />
            )}
          </div>
        )}

        {/* Actions */}
        <div className="flex items-center gap-4 pt-2 border-t border-gray-100">
          <button
            onClick={onLike}
            className={cn(
              'flex items-center gap-1.5 text-sm font-medium transition-colors',
              isLiked ? 'text-red-500' : 'text-gray-500 hover:text-red-500'
            )}
          >
            <Heart className={cn('h-5 w-5', isLiked && 'fill-current')} />
            {story.like_count > 0 && story.like_count}
          </button>
          <button
            onClick={loadComments}
            className="flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-blue-500 transition-colors"
          >
            <MessageCircle className="h-5 w-5" />
            {story.comment_count > 0 && story.comment_count}
          </button>
        </div>

        {/* Comments Section */}
        {showComments && (
          <div className="mt-4 pt-4 border-t border-gray-100">
            {loadingComments ? (
              <div className="text-sm text-gray-500 text-center py-2">Loading comments...</div>
            ) : comments.length === 0 ? (
              <div className="text-sm text-gray-500 text-center py-2">No comments yet</div>
            ) : (
              <div className="space-y-3 mb-4">
                {comments.map((comment) => (
                  <div key={comment.id} className="flex gap-2">
                    <Avatar
                      initials={comment.author_name.charAt(0).toUpperCase()}
                      size="sm"
                    />
                    <div className="flex-1 bg-gray-50 rounded-lg px-3 py-2">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-gray-900">
                          {comment.author_name}
                        </span>
                        <span className="text-xs text-gray-400">
                          {timeAgo(comment.created_at)}
                        </span>
                      </div>
                      <p className="text-sm text-gray-700">{comment.content}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Add Comment */}
            <form onSubmit={handleAddComment} className="flex gap-2">
              <input
                type="text"
                placeholder="Add a comment..."
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                className="flex-1 h-9 px-3 rounded-full border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <Button
                type="submit"
                size="sm"
                disabled={!newComment.trim()}
                className="rounded-full"
              >
                <Send className="h-4 w-4" />
              </Button>
            </form>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

interface CreateStoryModalProps {
  onClose: () => void
  onCreated: (story: Story) => void
  classroomId: string
  userId: string
  userName: string
}

function CreateStoryModal({ onClose, onCreated, classroomId, userId, userName }: CreateStoryModalProps) {
  const [content, setContent] = useState('')
  const [mediaFile, setMediaFile] = useState<File | null>(null)
  const [mediaPreview, setMediaPreview] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setMediaFile(file)
      const reader = new FileReader()
      reader.onloadend = () => {
        setMediaPreview(reader.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!content.trim() && !mediaFile) return

    setLoading(true)
    try {
      let mediaUrls: string[] = []
      let mediaType: MediaType = 'text'

      if (mediaFile) {
        // Create a temporary story ID for the upload path
        const tempId = crypto.randomUUID()
        if (mediaFile.type.startsWith('image/')) {
          const url = await storyService.uploadImage(mediaFile, tempId)
          mediaUrls = [url]
          mediaType = 'image'
        } else if (mediaFile.type.startsWith('video/')) {
          const url = await storyService.uploadVideo(mediaFile, tempId)
          mediaUrls = [url]
          mediaType = 'video'
        }
      }

      const newStory = await storyService.createStory(
        classroomId,
        userId,
        userName,
        content.trim() || undefined,
        mediaUrls,
        mediaType
      )

      onCreated(newStory)
    } catch (error) {
      console.error('Failed to create story:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <Card className="w-full max-w-lg mx-4">
        <div className="flex items-center justify-between p-4 border-b border-gray-100">
          <h2 className="text-lg font-semibold">Create Story</h2>
          <button onClick={onClose} className="p-2 rounded-lg hover:bg-gray-100">
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="p-4">
            <textarea
              placeholder="What's happening in class today?"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              className="w-full h-32 p-3 border border-gray-300 rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />

            {/* Media Preview */}
            {mediaPreview && (
              <div className="mt-4 relative">
                {mediaFile?.type.startsWith('image/') ? (
                  <img
                    src={mediaPreview}
                    alt="Preview"
                    className="w-full max-h-64 object-cover rounded-lg"
                  />
                ) : (
                  <video
                    src={mediaPreview}
                    controls
                    className="w-full max-h-64 rounded-lg"
                  />
                )}
                <button
                  type="button"
                  onClick={() => {
                    setMediaFile(null)
                    setMediaPreview(null)
                  }}
                  className="absolute top-2 right-2 p-1 bg-black/50 rounded-full text-white hover:bg-black/70"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            )}

            {/* Add Media Button */}
            <div className="mt-4 flex items-center gap-2">
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*,video/*"
                onChange={handleFileSelect}
                className="hidden"
              />
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => fileInputRef.current?.click()}
              >
                <ImageIcon className="h-4 w-4 mr-2" />
                Add Photo/Video
              </Button>
            </div>
          </div>

          <div className="p-4 border-t border-gray-100 flex justify-end gap-3">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button
              type="submit"
              loading={loading}
              disabled={!content.trim() && !mediaFile}
            >
              Post Story
            </Button>
          </div>
        </form>
      </Card>
    </div>
  )
}
