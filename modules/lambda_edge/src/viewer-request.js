'use strict';

/**
 * Lambda@Edge - Viewer Request Handler
 * URL 정규화 및 원본 이미지 경로 변환
 * 
 * 입력: /images/300x200/80/product.jpg
 * 출력 (S3로): /original/product.jpg
 * 
 * 리사이징 정보는 origin-response에서 처리
 */

exports.handler = async (event, context, callback) => {
    const request = event.Records[0].cf.request;
    const uri = request.uri;

    // 리사이징 URL 패턴 확인
    // /images/{width}x{height}/{quality}/{filename}
    // /images/{width}x{height}/{filename}
    const matchWithQuality = uri.match(/^\/images\/(\d+)x(\d+)\/(\d+)\/(.+)$/);
    const matchWithoutQuality = uri.match(/^\/images\/(\d+)x(\d+)\/(.+)$/);

    if (matchWithQuality) {
        // 품질 지정된 경우: /images/300x200/80/product.jpg
        const filename = matchWithQuality[4];
        // S3 원본 경로로 변환
        request.uri = `/original/${filename}`;

        // 리사이징 정보를 커스텀 헤더에 저장 (origin-response에서 사용)
        request.headers['x-resize-width'] = [{ key: 'X-Resize-Width', value: matchWithQuality[1] }];
        request.headers['x-resize-height'] = [{ key: 'X-Resize-Height', value: matchWithQuality[2] }];
        request.headers['x-resize-quality'] = [{ key: 'X-Resize-Quality', value: matchWithQuality[3] }];

    } else if (matchWithoutQuality) {
        // 품질 미지정된 경우: /images/300x200/product.jpg
        const filename = matchWithoutQuality[3];
        request.uri = `/original/${filename}`;

        request.headers['x-resize-width'] = [{ key: 'X-Resize-Width', value: matchWithoutQuality[1] }];
        request.headers['x-resize-height'] = [{ key: 'X-Resize-Height', value: matchWithoutQuality[2] }];
        request.headers['x-resize-quality'] = [{ key: 'X-Resize-Quality', value: '80' }]; // 기본 품질
    }

    // /original/ 경로는 그대로 통과
    // 그 외 경로도 그대로 통과

    return callback(null, request);
};
