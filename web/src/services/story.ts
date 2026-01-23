import { createClient } from '@/lib/supabase/client'
import type { Story, StoryComment, MediaType } from '@/types'

export class StoryError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'StoryError'
  }
}

export const storyService = {
  // Story CRUD operations

  async createStory(
    classId: string,
    authorId: string,
    authorName: string,
    content?: string,
    mediaUrls: string[] = [],
    mediaType: MediaType = 'text'
  ): Promise<Story> {
    const supabase = createClient()

    const newStory = {
      class_id: classId,
      author_id: authorId,
      author_name: authorName,
      content,
      media_urls: mediaUrls,
      media_type: mediaType,
      like_count: 0,
      liked_by_ids: [],
      comment_count: 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }

    const { data, error } = await supabase
      .from('stories')
      .insert(newStory)
      .select()
      .single()

    if (error) throw new StoryError(error.message)
    return data as Story
  },

  async getStoriesForClass(classId: string, limit: number = 20): Promise<Story[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('stories')
      .select()
      .eq('class_id', classId)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (error) throw new StoryError(error.message)
    return data as Story[]
  },

  async getStory(id: string): Promise<Story | null> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('stories')
      .select()
      .eq('id', id)
      .single()

    if (error) return null
    return data as Story
  },

  async updateStory(story: Partial<Story> & { id: string }): Promise<Story> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('stories')
      .update({ ...story, updated_at: new Date().toISOString() })
      .eq('id', story.id)
      .select()
      .single()

    if (error) throw new StoryError(error.message)
    return data as Story
  },

  async deleteStory(id: string): Promise<void> {
    const supabase = createClient()

    // Delete associated comments first
    await supabase
      .from('story_comments')
      .delete()
      .eq('story_id', id)

    // Delete the story
    const { error } = await supabase
      .from('stories')
      .delete()
      .eq('id', id)

    if (error) throw new StoryError(error.message)
  },

  // Like/unlike story

  async toggleLike(storyId: string, userId: string): Promise<Story> {
    const supabase = createClient()

    const story = await this.getStory(storyId)
    if (!story) throw new StoryError('Story not found')

    const isLiked = story.liked_by_ids.includes(userId)
    let updatedLikedByIds: string[]
    let updatedLikeCount: number

    if (isLiked) {
      // Unlike
      updatedLikedByIds = story.liked_by_ids.filter(id => id !== userId)
      updatedLikeCount = story.like_count - 1
    } else {
      // Like
      updatedLikedByIds = [...story.liked_by_ids, userId]
      updatedLikeCount = story.like_count + 1
    }

    const { data, error } = await supabase
      .from('stories')
      .update({
        liked_by_ids: updatedLikedByIds,
        like_count: updatedLikeCount,
        updated_at: new Date().toISOString(),
      })
      .eq('id', storyId)
      .select()
      .single()

    if (error) throw new StoryError(error.message)
    return data as Story
  },

  // Comment operations

  async addComment(
    storyId: string,
    authorId: string,
    authorName: string,
    content: string
  ): Promise<StoryComment> {
    const supabase = createClient()

    const newComment = {
      story_id: storyId,
      author_id: authorId,
      author_name: authorName,
      content,
      created_at: new Date().toISOString(),
    }

    const { data, error } = await supabase
      .from('story_comments')
      .insert(newComment)
      .select()
      .single()

    if (error) throw new StoryError(error.message)

    // Increment comment count using RPC function
    await supabase.rpc('increment_comment_count', { story_id: storyId })

    return data as StoryComment
  },

  async getComments(storyId: string): Promise<StoryComment[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('story_comments')
      .select()
      .eq('story_id', storyId)
      .order('created_at', { ascending: true })

    if (error) throw new StoryError(error.message)
    return data as StoryComment[]
  },

  async deleteComment(id: string, storyId: string): Promise<void> {
    const supabase = createClient()

    const { error } = await supabase
      .from('story_comments')
      .delete()
      .eq('id', id)

    if (error) throw new StoryError(error.message)

    // Decrement comment count
    await supabase.rpc('decrement_comment_count', { story_id: storyId })
  },

  // Media upload

  async uploadImage(file: File, storyId: string): Promise<string> {
    const supabase = createClient()

    const fileExt = file.name.split('.').pop()
    const fileName = `${crypto.randomUUID()}.${fileExt}`
    const filePath = `stories/${storyId}/${fileName}`

    const { error: uploadError } = await supabase.storage
      .from('media')
      .upload(filePath, file)

    if (uploadError) throw new StoryError(uploadError.message)

    const { data: { publicUrl } } = supabase.storage
      .from('media')
      .getPublicUrl(filePath)

    return publicUrl
  },

  async uploadVideo(file: File, storyId: string): Promise<string> {
    const supabase = createClient()

    const fileExt = file.name.split('.').pop()
    const fileName = `${crypto.randomUUID()}.${fileExt}`
    const filePath = `stories/${storyId}/${fileName}`

    const { error: uploadError } = await supabase.storage
      .from('media')
      .upload(filePath, file)

    if (uploadError) throw new StoryError(uploadError.message)

    const { data: { publicUrl } } = supabase.storage
      .from('media')
      .getPublicUrl(filePath)

    return publicUrl
  },

  async deleteMedia(url: string): Promise<void> {
    const supabase = createClient()

    // Extract path from URL
    const urlParts = url.split('/media/')
    if (urlParts.length < 2) return

    const filePath = urlParts[1]

    const { error } = await supabase.storage
      .from('media')
      .remove([filePath])

    if (error) throw new StoryError(error.message)
  },

  // Real-time subscriptions

  subscribeToStories(classId: string, callback: (stories: Story[]) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`stories_${classId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'stories', filter: `class_id=eq.${classId}` },
        async () => {
          const stories = await this.getStoriesForClass(classId)
          callback(stories)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },

  subscribeToComments(storyId: string, callback: (comments: StoryComment[]) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`comments_${storyId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'story_comments', filter: `story_id=eq.${storyId}` },
        async () => {
          const comments = await this.getComments(storyId)
          callback(comments)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },
}
