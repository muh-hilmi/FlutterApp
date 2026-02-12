package handler

import (
	"net/http"

	"github.com/anigmaa/backend/internal/infrastructure/storage"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

// UploadHandler handles file upload HTTP requests
type UploadHandler struct {
	storage storage.Storage
}

// NewUploadHandler creates a new upload handler
func NewUploadHandler(storage storage.Storage) *UploadHandler {
	return &UploadHandler{
		storage: storage,
	}
}

// UploadImage godoc
// @Summary Upload an image
// @Description Upload an image file to cloud storage
// @Tags upload
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param file formData file true "Image file"
// @Success 200 {object} response.Response{data=storage.UploadResult}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 413 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /upload/image [post]
func (h *UploadHandler) UploadImage(c *gin.Context) {
	// Get file from request
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		response.BadRequest(c, "No file uploaded", err.Error())
		return
	}
	defer file.Close()

	// Upload file
	result, err := h.storage.Upload(c.Request.Context(), file, header)
	if err != nil {
		if err.Error() == "file size exceeds maximum allowed size" {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{
				"error": gin.H{
					"code":    "FILE_TOO_LARGE",
					"message": err.Error(),
				},
			})
			return
		}
		response.InternalError(c, "Failed to upload file", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "File uploaded successfully", result)
}
