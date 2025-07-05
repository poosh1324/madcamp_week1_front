# 게시판 API 엔드포인트 명세서

## 기본 정보
- **Base URL**: `http://localhost:4000/api/board`
- **인증**: JWT Bearer Token
- **Content-Type**: `application/json`

## 1. 게시글 목록 조회
```
GET /api/board/posts
```

### 쿼리 파라미터
- `page` (optional): 페이지 번호 (기본값: 1)
- `limit` (optional): 페이지당 항목 수 (기본값: 20)
- `sortBy` (optional): 정렬 기준 ('createdAt', 'views', 'title')
- `sortOrder` (optional): 정렬 순서 ('asc', 'desc')
- `search` (optional): 검색어

### 응답 예시
```json
{
  "success": true,
  "posts": [
    {
      "id": 1,
      "title": "게시글 제목",
      "content": "게시글 내용",
      "author": "작성자명",
      "createdAt": "2023-12-01T10:00:00Z",
      "views": 42,
      "tags": ["태그1", "태그2"]
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalItems": 100
  }
}
```

## 2. 게시글 상세 조회
```
GET /api/board/posts/:id
```

### 응답 예시
```json
{
  "success": true,
  "post": {
    "id": 1,
    "title": "게시글 제목",
    "content": "게시글 내용",
    "author": "작성자명",
    "createdAt": "2023-12-01T10:00:00Z",
    "views": 43,
    "tags": ["태그1", "태그2"]
  }
}
```

## 3. 게시글 작성
```
POST /api/board/posts
```

### 요청 본문
```json
{
  "title": "새 게시글 제목",
  "content": "새 게시글 내용",
  "tags": ["태그1", "태그2"]
}
```

### 응답 예시
```json
{
  "success": true,
  "post": {
    "id": 123,
    "title": "새 게시글 제목",
    "content": "새 게시글 내용",
    "author": "작성자명",
    "createdAt": "2023-12-01T10:00:00Z",
    "views": 0,
    "tags": ["태그1", "태그2"]
  }
}
```

## 4. 게시글 수정
```
PUT /api/board/posts/:id
```

### 요청 본문
```json
{
  "title": "수정된 제목",
  "content": "수정된 내용",
  "tags": ["태그1", "태그2"]
}
```

## 5. 게시글 삭제
```
DELETE /api/board/posts/:id
```

### 응답 예시
```json
{
  "success": true,
  "message": "게시글이 삭제되었습니다."
}
```

## 6. 게시글 검색
```
GET /api/board/search
```

### 쿼리 파라미터
- `q`: 검색어 (필수)
- `category` (optional): 카테고리
- `tags` (optional): 태그 (쉼표로 구분)

## 7. 인기 게시글 조회
```
GET /api/board/popular
```

### 쿼리 파라미터
- `limit` (optional): 개수 제한 (기본값: 10)

## 8. 내가 작성한 게시글 조회
```
GET /api/board/my-posts
```

### 쿼리 파라미터
- `page` (optional): 페이지 번호
- `limit` (optional): 페이지당 항목 수

## 에러 응답 형식
```json
{
  "success": false,
  "error": "에러 메시지",
  "code": "ERROR_CODE"
}
```

## HTTP 상태 코드
- `200`: 성공
- `201`: 생성 성공
- `400`: 잘못된 요청
- `401`: 인증 실패
- `403`: 권한 없음
- `404`: 리소스 없음
- `500`: 서버 내부 오류 